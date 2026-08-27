class CloudflareAccessVerifier
  JWKS_CACHE_KEY = "cloudflare_access_jwks"
  JWKS_CACHE_TTL = 1.hour

  def self.call(token)
    new(token).verify
  end

  def initialize(token)
    @token = token
  end

  # Returns JWT payload hash or nil if invalid.
  def verify
    issuer = HostedInstanceConfig.cloudflare_access_issuer
    aud = HostedInstanceConfig.cloudflare_access_aud
    return nil unless issuer && aud

    unverified = JWT.decode(@token, nil, false).first
    iss = unverified["iss"].to_s
    return nil unless iss == issuer

    keys = fetch_keys(issuer)
    return nil if keys.empty?

    keys.each do |key|
      decoded = JWT.decode(
        @token, key, true,
        algorithms: [ "RS256" ],
        aud: aud,
        verify_aud: true,
        iss: issuer,
        verify_iss: true,
        verify_expiration: true
      )
      return decoded.first
    rescue JWT::DecodeError
      next
    end

    nil
  rescue StandardError
    nil
  end

  private

  def fetch_keys(iss)
    cached = Rails.cache.read("#{JWKS_CACHE_KEY}/#{iss}")
    return cached if cached

    response = Faraday.get("#{iss}/cdn-cgi/access/certs")
    return [] unless response.success?

    jwks_data = JSON.parse(response.body)
    keys = jwks_data["keys"].filter_map do |k|
      JWT::JWK.new(k.transform_keys(&:to_sym)).public_key
    rescue StandardError
      nil
    end

    Rails.cache.write("#{JWKS_CACHE_KEY}/#{iss}", keys, expires_in: JWKS_CACHE_TTL) if keys.any?
    keys
  rescue StandardError
    []
  end
end
