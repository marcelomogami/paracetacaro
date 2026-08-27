require "rails_helper"

RSpec.describe PharmacyConfig, "YAMLs de produção" do
  # Todas as farmácias com YAML versionado, habilitadas ou não.
  TODAS = %w[paguemenos drogariasaopaulo rosario drogasil].freeze
  # As que devem aparecer nas buscas (enabled: true).
  ATIVAS = %w[paguemenos drogariasaopaulo rosario].freeze

  TODAS.each do |slug|
    describe slug do
      subject(:config) { PharmacyConfig.load(slug) }

      it "carrega sem erro" do
        expect { config }.not_to raise_error
      end

      it "tem nome e slug preenchidos" do
        expect(config.name).to be_present
        expect(config.slug).to eq(slug)
      end

      it "tem URL de busca com placeholder {query}" do
        expect(config.search["url"]).to include("{query}")
      end

      it "search_url interpola a query corretamente" do
        url = config.search_url("paracetamol")
        expect(url).to include("paracetamol")
        expect(url).not_to include("{query}")
      end
    end
  end

  describe "farmácias ativas (mode: api via VTEX)" do
    ATIVAS.each do |slug|
      describe slug do
        subject(:config) { PharmacyConfig.load(slug) }

        it "está habilitada" do
          expect(config.enabled?).to be true
        end

        it "é mode: api" do
          expect(config.api?).to be true
        end

        it "não precisa de JS" do
          expect(config.needs_js?).to be false
        end

        it "tem os campos obrigatórios mapeados" do
          expect(config.fields["nome"]).to be_present
          expect(config.fields["preco"]).to be_present
          expect(config.fields["url"]).to be_present
        end
      end
    end
  end

  describe "load_all" do
    subject(:slugs) { PharmacyConfig.load_all.map(&:slug) }

    it "retorna apenas as farmácias habilitadas" do
      expect(slugs).to match_array(ATIVAS)
    end

    it "não inclui o Drogasil (desabilitado por bloqueio Akamai)" do
      expect(slugs).not_to include("drogasil")
    end
  end

  describe "drogasil (desabilitado)" do
    subject(:config) { PharmacyConfig.load("drogasil") }

    it "está desabilitado" do
      expect(config.enabled?).to be false
    end
  end
end
