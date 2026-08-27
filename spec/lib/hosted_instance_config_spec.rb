require "rails_helper"

RSpec.describe HostedInstanceConfig do
  describe ".app_host" do
    it "returns the configured application host" do
      expect(described_class.app_host({ "APP_HOST" => "app.example.com" })).to eq("app.example.com")
    end

    it "raises when the host is required but missing" do
      expect { described_class.app_host({}) }.to raise_error(KeyError)
    end
  end

  describe ".mailer_from" do
    it "returns the configured sender" do
      env = { "MAILER_FROM" => "Example <noreply@example.com>" }

      expect(described_class.mailer_from(env, required: true)).to eq("Example <noreply@example.com>")
    end

    it "uses an example sender outside production" do
      expect(described_class.mailer_from({})).to eq("Paracetacaro <noreply@example.com>")
    end

    it "raises when the sender is required but missing" do
      expect { described_class.mailer_from({}, required: true) }.to raise_error(KeyError)
    end
  end

  describe ".cloudflare_access_aud" do
    it "returns a present value" do
      expect(described_class.cloudflare_access_aud({ "CLOUDFLARE_ACCESS_AUD" => "aud-tag" })).to eq("aud-tag")
    end

    it "returns nil for blank values" do
      expect(described_class.cloudflare_access_aud({ "CLOUDFLARE_ACCESS_AUD" => "  " })).to be_nil
    end
  end

  describe ".cloudflare_access_issuer" do
    it "normalizes a trailing slash" do
      env = { "CLOUDFLARE_ACCESS_ISSUER" => "https://team.cloudflareaccess.com/" }

      expect(described_class.cloudflare_access_issuer(env)).to eq("https://team.cloudflareaccess.com")
    end

    it "returns nil for blank values" do
      expect(described_class.cloudflare_access_issuer({})).to be_nil
    end

    it "rejects an issuer outside Cloudflare Access" do
      env = { "CLOUDFLARE_ACCESS_ISSUER" => "https://example.com" }

      expect { described_class.cloudflare_access_issuer(env) }.to raise_error(ArgumentError)
    end

    it "rejects a non-HTTPS issuer" do
      env = { "CLOUDFLARE_ACCESS_ISSUER" => "http://team.cloudflareaccess.com" }

      expect { described_class.cloudflare_access_issuer(env) }.to raise_error(ArgumentError)
    end
  end

  describe ".cloudflare_access_logout_url" do
    it "builds the logout URL from the configured issuer" do
      env = { "CLOUDFLARE_ACCESS_ISSUER" => "https://team.cloudflareaccess.com" }

      expect(described_class.cloudflare_access_logout_url(env)).to eq(
        "https://team.cloudflareaccess.com/cdn-cgi/access/logout"
      )
    end

    it "returns nil without an issuer" do
      expect(described_class.cloudflare_access_logout_url({})).to be_nil
    end
  end
end
