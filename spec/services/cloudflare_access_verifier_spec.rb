require "rails_helper"

RSpec.describe CloudflareAccessVerifier do
  subject(:verifier) { described_class.new(token) }

  let(:token) { "header.payload.signature" }
  let(:issuer) { "https://team.cloudflareaccess.com" }
  let(:aud) { "aud-tag" }

  before do
    allow(HostedInstanceConfig).to receive(:cloudflare_access_issuer).and_return(issuer)
    allow(HostedInstanceConfig).to receive(:cloudflare_access_aud).and_return(aud)
  end

  it "returns nil before decoding when configuration is missing" do
    allow(HostedInstanceConfig).to receive(:cloudflare_access_aud).and_return(nil)

    expect(JWT).not_to receive(:decode)
    expect(verifier.verify).to be_nil
  end

  it "rejects a token issued by a different Cloudflare Access team" do
    allow(JWT).to receive(:decode).with(token, nil, false).and_return([ { "iss" => "https://other.cloudflareaccess.com" } ])

    expect(verifier).not_to receive(:fetch_keys)
    expect(verifier.verify).to be_nil
  end

  it "verifies the signature, configured issuer, audience, and expiration" do
    payload = { "iss" => issuer, "email" => "user@example.com" }
    key = instance_double(OpenSSL::PKey::RSA)

    allow(JWT).to receive(:decode).with(token, nil, false).and_return([ { "iss" => issuer } ])
    allow(verifier).to receive(:fetch_keys).with(issuer).and_return([ key ])
    expect(JWT).to receive(:decode).with(
      token,
      key,
      true,
      algorithms: [ "RS256" ],
      aud: aud,
      verify_aud: true,
      iss: issuer,
      verify_iss: true,
      verify_expiration: true
    ).and_return([ payload ])

    expect(verifier.verify).to eq(payload)
  end
end
