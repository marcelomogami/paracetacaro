require "rails_helper"

RSpec.describe "Searches", type: :request do
  let(:user) { create(:user) }
  before { login_as(user) }

  describe "GET /" do
    it "renderiza o formulário sem query" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    context "com query" do
      let(:config_pague) do
        instance_double(PharmacyConfig,
          slug: "paguemenos", name: "Pague Menos", enabled?: true)
      end
      let(:config_dsp) do
        instance_double(PharmacyConfig,
          slug: "drogariasaopaulo", name: "Drogaria SP", enabled?: true)
      end
      let(:config) { config_pague }

      before { allow(PharmacyConfig).to receive(:load_all).and_return([ config ]) }

      it "renderiza com status 200" do
        get root_path, params: { q: "paracetamol" }
        expect(response).to have_http_status(:ok)
      end

      it "enfileira um SearchJob por farmácia habilitada" do
        expect {
          get root_path, params: { q: "paracetamol" }
        }.to have_enqueued_job(SearchJob).with(
          hash_including(query: "paracetamol", pharmacy_slug: "paguemenos")
        )
      end

      it "usa o mesmo stream_name para a mesma query" do
        get root_path, params: { q: "paracetamol" }
        stream_name_1 = response.body.scan(/search-[a-f0-9-]+/).first

        get root_path, params: { q: "paracetamol" }
        stream_name_2 = response.body.scan(/search-[a-f0-9-]+/).first

        expect(stream_name_1).to eq(stream_name_2)
      end

      it "não enfileira jobs sem query" do
        expect {
          get root_path
        }.not_to have_enqueued_job(SearchJob)
      end

      context "com seleção de farmácias via params" do
        before do
          allow(PharmacyConfig).to receive(:load_all)
            .and_return([ config_pague, config_dsp ])
        end

        it "busca apenas as farmácias selecionadas" do
          expect {
            get root_path, params: { q: "paracetamol", pharmacies: [ "paguemenos" ] }
          }.to have_enqueued_job(SearchJob).with(
            hash_including(pharmacy_slug: "paguemenos")
          ).exactly(:once)
        end

        it "não enfileira job para farmácia não selecionada" do
          expect {
            get root_path, params: { q: "paracetamol", pharmacies: [ "paguemenos" ] }
          }.not_to have_enqueued_job(SearchJob).with(
            hash_including(pharmacy_slug: "drogariasaopaulo")
          )
        end

        it "não exibe linha da farmácia não selecionada" do
          get root_path, params: { q: "paracetamol", pharmacies: [ "paguemenos" ] }
          expect(response.body).not_to include("pharmacy_drogariasaopaulo_results")
        end

        it "busca todas as farmácias quando nenhuma é passada" do
          expect {
            get root_path, params: { q: "paracetamol" }
          }.to have_enqueued_job(SearchJob).with(hash_including(pharmacy_slug: "paguemenos"))
            .and have_enqueued_job(SearchJob).with(hash_including(pharmacy_slug: "drogariasaopaulo"))
        end
      end

      context "com resultado em cache" do
        before do
          Rails.cache = ActiveSupport::Cache::MemoryStore.new
          key = SearchJob.cache_key_for("paracetamol", "paguemenos")
          Rails.cache.write(key, [])
        end

        after { Rails.cache = ActiveSupport::Cache::NullStore.new }

        it "não enfileira job para farmácia com cache" do
          expect {
            get root_path, params: { q: "paracetamol" }
          }.not_to have_enqueued_job(SearchJob)
        end

        it "renderiza os resultados sem estado de carregamento" do
          get root_path, params: { q: "paracetamol" }
          expect(response.body).not_to include("Buscando")
        end
      end
    end
  end
end
