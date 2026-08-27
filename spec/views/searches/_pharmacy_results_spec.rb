require "rails_helper"

RSpec.describe "searches/_pharmacy_results", type: :view do
  let(:config) { instance_double(PharmacyConfig, name: "Pague Menos", slug: "paguemenos") }

  let(:result_com_desconto) do
    PharmacyResult.new(
      farmacia_slug: "paguemenos", farmacia_nome: "Pague Menos",
      nome: "Paracetamol 500mg 20 Comprimidos",
      fabricante: "Medley", apresentacao: nil,
      preco: 4.99, preco_original: 6.99,
      url: "https://example.com/p1",
      imagem: "https://example.com/img.jpg",
      sku_id: "11111111",
      promocao: "LEVE3 PAGUE2",
      vendedor: nil
    )
  end

  let(:result_sem_desconto) do
    PharmacyResult.new(
      farmacia_slug: "paguemenos", farmacia_nome: "Pague Menos",
      nome: "Paracetamol 750mg 20 Comprimidos",
      fabricante: nil, apresentacao: nil,
      preco: 7.89, preco_original: nil,
      url: "https://example.com/p2",
      imagem: nil,
      sku_id: nil,
      promocao: nil,
      vendedor: nil
    )
  end

  context "com resultados" do
    before do
      render partial: "searches/pharmacy_results",
             locals: { results: [ result_com_desconto, result_sem_desconto ], config: config, query: "paracetamol" }
    end

    it "inclui o id correto para o Turbo Stream substituir" do
      expect(rendered).to include('id="pharmacy_paguemenos_results"')
    end

    it "exibe o nome do produto" do
      expect(rendered).to include("Paracetamol 500mg 20 Comprimidos")
    end

    it "exibe o fabricante quando presente" do
      expect(rendered).to include("Medley")
    end

    it "exibe o preço formatado em reais" do
      expect(rendered).to include("4,99")
    end

    it "exibe o preço original riscado quando há desconto" do
      expect(rendered).to include("6,99")
    end

    it "não exibe preço original quando não há desconto" do
      expect(rendered).not_to include("7,89").twice
    end

    it "exibe a imagem quando presente" do
      expect(rendered).to include("https://example.com/img.jpg")
    end

    it "exibe link para o produto" do
      expect(rendered).to include("https://example.com/p1")
    end
  end

  context "sem resultados" do
    before do
      render partial: "searches/pharmacy_results",
             locals: { results: [], config: config, query: "paracetamol" }
    end

    it "exibe mensagem de nenhum resultado" do
      expect(rendered).to include("Nenhum resultado")
    end
  end
end
