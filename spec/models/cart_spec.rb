require "rails_helper"

RSpec.describe Cart, type: :model do
  it { is_expected.to have_many(:cart_items).dependent(:destroy) }

  describe "nome padrão" do
    it "define um nome ao criar sem informar" do
      cart = Cart.create!
      expect(cart.name).to be_present
    end

    it "preserva nome informado explicitamente" do
      cart = Cart.create!(name: "Meu Carrinho")
      expect(cart.name).to eq("Meu Carrinho")
    end
  end

  describe "#pharmacy_total" do
    let(:cart)  { create(:cart) }
    let!(:item1) { create(:cart_item, cart: cart, query: "ibuprofeno") }
    let!(:item2) { create(:cart_item, cart: cart, query: "paracetamol") }

    context "todos os itens com seleção para a farmácia" do
      before do
        create(:cart_selection, cart_item: item1, pharmacy_slug: "paguemenos", preco: 12.90)
        create(:cart_selection, cart_item: item2, pharmacy_slug: "paguemenos", preco: 8.00)
      end

      it "retorna a soma dos preços" do
        expect(cart.pharmacy_total("paguemenos")).to eq(20.90)
      end
    end

    context "algum item sem seleção para a farmácia" do
      before { create(:cart_selection, cart_item: item1, pharmacy_slug: "paguemenos", preco: 12.90) }

      it "retorna nil (total incompleto)" do
        expect(cart.pharmacy_total("paguemenos")).to be_nil
      end
    end

    context "nenhum item com seleção para a farmácia" do
      it "retorna nil" do
        expect(cart.pharmacy_total("paguemenos")).to be_nil
      end
    end
  end

  describe "#ideal_total" do
    let(:cart) { create(:cart) }
    let!(:item) { create(:cart_item, cart: cart) }

    before do
      create(:cart_selection, cart_item: item, pharmacy_slug: "paguemenos", preco: 12.90)
      create(:cart_selection, cart_item: item, pharmacy_slug: "rosario", preco: 11.50)
    end

    it "retorna a soma dos menores preços por item" do
      expect(cart.ideal_total).to eq(11.50)
    end
  end

  describe "#cheapest_pharmacy_slug / #priciest_pharmacy_slug" do
    let(:cart)  { create(:cart) }
    let!(:item1) { create(:cart_item, cart: cart, query: "ibuprofeno") }
    let!(:item2) { create(:cart_item, cart: cart, query: "paracetamol") }

    before do
      create(:cart_selection, cart_item: item1, pharmacy_slug: "paguemenos",      preco: 12.90)
      create(:cart_selection, cart_item: item2, pharmacy_slug: "paguemenos",      preco: 8.00)
      create(:cart_selection, cart_item: item1, pharmacy_slug: "drogariasaopaulo", preco: 11.00)
      create(:cart_selection, cart_item: item2, pharmacy_slug: "drogariasaopaulo", preco: 9.50)
    end

    let(:slugs) { %w[paguemenos drogariasaopaulo] }

    it "retorna o slug com menor total" do
      expect(cart.cheapest_pharmacy_slug(slugs)).to eq("drogariasaopaulo")
    end

    it "retorna o slug com maior total" do
      expect(cart.priciest_pharmacy_slug(slugs)).to eq("paguemenos")
    end

    context "quando os totais são iguais" do
      before do
        create(:cart_selection, cart_item: item1, pharmacy_slug: "rosario", preco: 12.90)
        create(:cart_selection, cart_item: item2, pharmacy_slug: "rosario", preco: 8.00)
      end

      it "cheapest retorna nil" do
        # paguemenos e rosario ambos com total 20.90
        expect(cart.cheapest_pharmacy_slug(%w[paguemenos rosario])).to be_nil
      end
    end

    context "quando alguma farmácia não tem total completo" do
      it "ignora farmácias sem total ao calcular" do
        expect(cart.cheapest_pharmacy_slug(slugs + %w[rosario])).to eq("drogariasaopaulo")
      end
    end
  end

  describe "#ideal_pharmacies_count" do
    let(:cart)  { create(:cart) }
    let!(:item1) { create(:cart_item, cart: cart, query: "ibuprofeno") }
    let!(:item2) { create(:cart_item, cart: cart, query: "paracetamol") }

    before do
      create(:cart_selection, cart_item: item1, pharmacy_slug: "paguemenos", preco: 12.90)
      create(:cart_selection, cart_item: item2, pharmacy_slug: "rosario",    preco: 8.00)
    end

    it "conta as farmácias distintas na compra ideal" do
      expect(cart.ideal_pharmacies_count).to eq(2)
    end
  end
end
