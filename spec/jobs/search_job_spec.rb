require "rails_helper"

RSpec.describe SearchJob, type: :job do
  let(:pharmacies_path) { Rails.root.join("spec/fixtures/pharmacies") }
  let(:query)       { "paracetamol" }
  let(:stream_name) { "search-test-stream" }
  let(:config)      { PharmacyConfig.load("test_api", base_path: pharmacies_path) }
  let(:results) do
    [
      PharmacyResult.new(
        farmacia_slug: "test_api", farmacia_nome: "Test API",
        nome: "Paracetamol 500mg 20 Comprimidos", preco: 4.99,
        url: "https://example.com/p", fabricante: "Medley",
        apresentacao: nil, preco_original: 6.99, imagem: nil, sku_id: "12345678",
        promocao: nil, vendedor: nil
      )
    ]
  end
  let(:extractor) { instance_double(PharmacyExtractor, search: results) }

  before do
    allow(PharmacyConfig).to receive(:load).with("test_api").and_return(config)
    allow(PharmacyExtractor).to receive(:new).with(config).and_return(extractor)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  it "pode ser enfileirado" do
    expect {
      SearchJob.perform_later(query: query, pharmacy_slug: "test_api", stream_name: stream_name)
    }.to have_enqueued_job(SearchJob).with(query: query, pharmacy_slug: "test_api", stream_name: stream_name)
  end

  it "carrega a config e executa o extrator" do
    SearchJob.perform_now(query: query, pharmacy_slug: "test_api", stream_name: stream_name)
    expect(extractor).to have_received(:search).with(query)
  end

  it "transmite os resultados para o target correto" do
    SearchJob.perform_now(query: query, pharmacy_slug: "test_api", stream_name: stream_name)
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
      stream_name,
      hash_including(target: "pharmacy_test_api_results")
    )
  end

  describe ".cache_key_for" do
    it "gera chave determinística para query + farmácia" do
      key1 = SearchJob.cache_key_for("Paracetamol ", "paguemenos")
      key2 = SearchJob.cache_key_for("paracetamol", "paguemenos")
      expect(key1).to eq(key2)
    end

    it "distingue farmácias diferentes" do
      expect(SearchJob.cache_key_for("paracetamol", "paguemenos"))
        .not_to eq(SearchJob.cache_key_for("paracetamol", "rosario"))
    end
  end

  it "usa cache para a mesma query + farmácia" do
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    SearchJob.perform_now(query: query, pharmacy_slug: "test_api", stream_name: stream_name)
    SearchJob.perform_now(query: query, pharmacy_slug: "test_api", stream_name: stream_name)
    expect(extractor).to have_received(:search).once
  ensure
    Rails.cache = ActiveSupport::Cache::NullStore.new
  end

  context "quando o extrator levanta erro" do
    before do
      allow(PharmacyExtractor).to receive(:new).and_raise(StandardError, "timeout")
    end

    it "transmite o erro em vez de explodir" do
      expect {
        SearchJob.perform_now(query: query, pharmacy_slug: "test_api", stream_name: stream_name)
      }.not_to raise_error
    end

    it "transmite para o mesmo target" do
      SearchJob.perform_now(query: query, pharmacy_slug: "test_api", stream_name: stream_name)
      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        stream_name,
        hash_including(target: "pharmacy_test_api_results")
      )
    end
  end
end
