require "rails_helper"

RSpec.describe PharmacyExtractor do
  let(:pharmacies_path) { Rails.root.join("spec/fixtures/pharmacies") }
  let(:responses_path)  { Rails.root.join("spec/fixtures/responses") }

  describe "mode: api" do
    let(:config) { PharmacyConfig.load("test_api", base_path: pharmacies_path) }
    let(:search_url) { "https://example.com/api/search/paracetamol" }

    before do
      stub_request(:get, search_url)
        .to_return(
          body: File.read(responses_path.join("test_api_response.json")),
          headers: { "Content-Type" => "application/json" }
        )
    end

    subject(:results) { PharmacyExtractor.new(config).search("paracetamol") }

    it "retorna um array de PharmacyResult" do
      expect(results).to all(be_a(PharmacyResult))
    end

    it "retorna apenas produtos disponíveis (filtra IsAvailable: false)" do
      expect(results.size).to eq(2)
    end

    it "exclui produto com IsAvailable: false dos resultados" do
      nomes = results.map(&:nome)
      expect(nomes).not_to include("Paracetamol 1g 20 Comprimidos")
    end

    it "extrai nome" do
      expect(results.first.nome).to eq("Paracetamol 500mg 20 Comprimidos")
    end

    it "extrai preco como Float" do
      expect(results.first.preco).to eq(4.99)
    end

    it "extrai preco_original" do
      expect(results.first.preco_original).to eq(6.99)
    end

    it "extrai fabricante" do
      expect(results.first.fabricante).to eq("Medley")
    end

    it "extrai url" do
      expect(results.first.url).to eq("https://example.com/paracetamol-500mg/p")
    end

    it "inclui slug e nome da farmácia" do
      expect(results.first.farmacia_slug).to eq("test_api")
      expect(results.first.farmacia_nome).to eq("Test API")
    end

    it "extrai promocao do primeiro caminho quando Teasers tem itens" do
      expect(results.first.promocao).to eq("LEVE3 PAGUE2")
    end

    it "extrai promocao do caminho alternativo (DiscountHighLight) quando Teasers está vazio" do
      expect(results.last.promocao).to eq("SUPEROFERTA")
    end

    it "retorna nil para vendedor quando sellerId é 1 (próprio)" do
      expect(results.first.vendedor).to be_nil
    end

    it "retorna nome do seller quando sellerId != 1 (marketplace)" do
      expect(results.last.vendedor).to eq("Unicpharma")
    end

    it "retorna nil para promocao quando campo não está configurado" do
      config_sem_promocao = PharmacyConfig.load("test_api_no_checkout", base_path: pharmacies_path)
      stub_request(:get, "https://example.com/api/no_checkout/paracetamol")
        .to_return(
          body: File.read(responses_path.join("test_api_response.json")),
          headers: { "Content-Type" => "application/json" }
        )
      results = PharmacyExtractor.new(config_sem_promocao).search("paracetamol")
      expect(results.first.promocao).to be_nil
    end

    it "retorna todos os produtos quando disponivel não está configurado" do
      config_sem_disponivel = PharmacyConfig.load("test_api_no_checkout", base_path: pharmacies_path)
      stub_request(:get, "https://example.com/api/no_checkout/paracetamol")
        .to_return(
          body: File.read(responses_path.join("test_api_response.json")),
          headers: { "Content-Type" => "application/json" }
        )
      results = PharmacyExtractor.new(config_sem_disponivel).search("paracetamol")
      expect(results.size).to eq(3)
    end
  end

  describe "formatação de teaser VTEX" do
    let(:extractor) { PharmacyExtractor.new(double) }

    it "prefixa número com - e % quando teaser começa com dígitos" do
      expect(extractor.send(:format_teaser, "60 DESCONTO NA SEGUNDA UNIDADE")).to eq("-60% DESCONTO NA SEGUNDA UNIDADE")
    end

    it "não altera teaser que não começa com número" do
      expect(extractor.send(:format_teaser, "LEVE3 PAGUE2")).to eq("LEVE3 PAGUE2")
      expect(extractor.send(:format_teaser, "SUPEROFERTA")).to eq("SUPEROFERTA")
    end

    it "retorna nil para teaser nil" do
      expect(extractor.send(:format_teaser, nil)).to be_nil
    end
  end

  describe "farmácia real: Rosário (VTEX com Teasers C#)" do
    let(:config) { PharmacyConfig.load("rosario") }
    let(:search_url) { "https://www.drogariarosario.com.br/api/catalog_system/pub/products/search/allegra?_from=0&_to=19" }

    before do
      stub_request(:get, search_url)
        .to_return(
          body: File.read(responses_path.join("rosario_response.json")),
          headers: { "Content-Type" => "application/json" }
        )
    end

    subject(:results) { PharmacyExtractor.new(config).search("allegra") }

    it "extrai promocao no formato C# (<Name>k__BackingField)" do
      expect(results.first.promocao).to eq("38% OFF na 2ª Unidade")
    end

    it "retorna nil para promocao quando Teasers está vazio" do
      expect(results.last.promocao).to be_nil
    end
  end

  describe "mode: html (sem JS)" do
    let(:config) { PharmacyConfig.load("test_html_nojs", base_path: pharmacies_path) }
    let(:search_url) { "https://example.com/search?q=paracetamol" }

    before do
      stub_request(:get, search_url)
        .to_return(
          body: File.read(responses_path.join("test_html_response.html")),
          headers: { "Content-Type" => "text/html" }
        )
    end

    subject(:results) { PharmacyExtractor.new(config).search("paracetamol") }

    it "retorna um array de PharmacyResult" do
      expect(results).to all(be_a(PharmacyResult))
    end

    it "retorna todos os produtos do HTML" do
      expect(results.size).to eq(2)
    end

    it "extrai nome" do
      expect(results.first.nome).to eq("Paracetamol 500mg 20 Comprimidos")
    end

    it "normaliza preco em formato brasileiro (R$ 4,99 → 4.99)" do
      expect(results.first.preco).to eq(4.99)
    end

    it "extrai url como atributo href" do
      expect(results.first.url).to eq("https://example.com/paracetamol-500mg")
    end

    it "extrai imagem como atributo src" do
      expect(results.first.imagem).to eq("https://example.com/paracetamol.jpg")
    end
  end

  describe "mode: html (com JS via Ferrum)" do
    let(:config) { PharmacyConfig.load("test_html", base_path: pharmacies_path) }
    let(:html_body) { File.read(responses_path.join("test_html_response.html")) }

    it "usa fetch_with_ferrum quando needs_js? é true" do
      extractor = PharmacyExtractor.new(config)
      allow(extractor).to receive(:fetch_with_ferrum).and_return(html_body)

      results = extractor.search("paracetamol")
      expect(extractor).to have_received(:fetch_with_ferrum)
      expect(results.first.nome).to eq("Paracetamol 500mg 20 Comprimidos")
    end

    it "inicializa o Chromium com flags seguras para container (no-sandbox)" do
      browser = instance_double(Ferrum::Browser, goto: nil, body: html_body, quit: nil)
      allow(browser).to receive_message_chain(:network, :wait_for_idle)

      expect(Ferrum::Browser).to receive(:new).with(
        hash_including(browser_options: hash_including("no-sandbox" => nil, "disable-dev-shm-usage" => nil))
      ).and_return(browser)

      PharmacyExtractor.new(config).send(:fetch_with_ferrum, "https://example.com")
    end
  end
end
