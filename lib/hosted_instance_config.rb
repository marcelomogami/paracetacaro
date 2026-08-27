require "uri"

module HostedInstanceConfig
  DEFAULT_MAILER_FROM = "Paracetacaro <noreply@example.com>"
  CLOUDFLARE_ACCESS_HOST_SUFFIX = ".cloudflareaccess.com"

  module_function

  def app_host(env = ENV)
    env.fetch("APP_HOST")
  end

  def mailer_from(env = ENV, required: false)
    return env.fetch("MAILER_FROM") if required

    optional_value(env, "MAILER_FROM") || DEFAULT_MAILER_FROM
  end

  def cloudflare_access_aud(env = ENV)
    optional_value(env, "CLOUDFLARE_ACCESS_AUD")
  end

  def cloudflare_access_issuer(env = ENV)
    value = optional_value(env, "CLOUDFLARE_ACCESS_ISSUER")
    return unless value

    uri = URI.parse(value)
    valid = uri.is_a?(URI::HTTPS) &&
      uri.host&.end_with?(CLOUDFLARE_ACCESS_HOST_SUFFIX) &&
      [ "", "/" ].include?(uri.path) &&
      uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil?
    raise ArgumentError, "CLOUDFLARE_ACCESS_ISSUER must be an HTTPS Cloudflare Access team URL" unless valid

    "https://#{uri.host}"
  rescue URI::InvalidURIError
    raise ArgumentError, "CLOUDFLARE_ACCESS_ISSUER must be a valid URL"
  end

  def cloudflare_access_logout_url(env = ENV)
    issuer = cloudflare_access_issuer(env)
    "#{issuer}/cdn-cgi/access/logout" if issuer
  end

  def optional_value(env, key)
    value = env[key].to_s.strip
    value unless value.empty?
  end
  private_class_method :optional_value
end
