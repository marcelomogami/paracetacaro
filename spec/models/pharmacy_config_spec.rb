require "rails_helper"

RSpec.describe PharmacyConfig do
  let(:fixtures_path) { Rails.root.join("spec/fixtures/pharmacies") }

  describe ".load" do
    it "carrega YAML de mode: api válido" do
      config = PharmacyConfig.load("test_api", base_path: fixtures_path)
      expect(config.name).to eq("Test API")
      expect(config.slug).to eq("test_api")
      expect(config.mode).to eq("api")
    end

    it "carrega YAML de mode: html válido" do
      config = PharmacyConfig.load("test_html", base_path: fixtures_path)
      expect(config.name).to eq("Test HTML")
      expect(config.mode).to eq("html")
    end

    it "levanta InvalidConfig para YAML sem campos obrigatórios" do
      expect { PharmacyConfig.load("test_invalid", base_path: fixtures_path) }
        .to raise_error(PharmacyConfig::InvalidConfig)
    end

    it "levanta erro para arquivo inexistente" do
      expect { PharmacyConfig.load("nao_existe", base_path: fixtures_path) }
        .to raise_error(Errno::ENOENT)
    end
  end

  describe ".load_all" do
    it "carrega todas as farmácias habilitadas do diretório" do
      configs = PharmacyConfig.load_all(base_path: fixtures_path)
      expect(configs.map(&:slug)).to include("test_api", "test_html")
    end
  end

  describe "#api? / #html?" do
    it "api? é true para mode: api" do
      config = PharmacyConfig.load("test_api", base_path: fixtures_path)
      expect(config.api?).to be true
      expect(config.html?).to be false
    end

    it "html? é true para mode: html" do
      config = PharmacyConfig.load("test_html", base_path: fixtures_path)
      expect(config.html?).to be true
      expect(config.api?).to be false
    end
  end

  describe "#needs_js?" do
    it "é false para mode: api" do
      config = PharmacyConfig.load("test_api", base_path: fixtures_path)
      expect(config.needs_js?).to be false
    end

    it "reflete needs_js do YAML para mode: html" do
      config = PharmacyConfig.load("test_html", base_path: fixtures_path)
      expect(config.needs_js?).to be true
    end
  end

  describe "#enabled?" do
    it "é true quando enabled: true" do
      config = PharmacyConfig.load("test_api", base_path: fixtures_path)
      expect(config.enabled?).to be true
    end
  end

  describe "#search_url" do
    it "interpola {query} na URL" do
      config = PharmacyConfig.load("test_api", base_path: fixtures_path)
      expect(config.search_url("paracetamol")).to include("paracetamol")
      expect(config.search_url("paracetamol")).not_to include("{query}")
    end
  end

  describe "#checkout?" do
    it "é true por padrão para farmácias VTEX" do
      config = PharmacyConfig.new(
        "name" => "Test", "slug" => "test", "mode" => "api", "enabled" => true,
        "search" => { "url" => "https://example.com/search/{query}" },
        "fields" => { "nome" => "n", "preco" => "p", "url" => "u", "sku_id" => "id" }
      )
      expect(config.checkout?).to be true
    end

    it "é false quando checkout: false está no YAML" do
      config = PharmacyConfig.load("test_api_no_checkout", base_path: fixtures_path)
      expect(config.checkout?).to be false
    end

    it "é false para farmácias sem sku_id" do
      config = PharmacyConfig.load("test_api", base_path: fixtures_path)
      expect(config.checkout?).to be false
    end
  end
end
