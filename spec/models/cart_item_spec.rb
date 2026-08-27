require "rails_helper"

RSpec.describe CartItem, type: :model do
  it { is_expected.to belong_to(:cart) }
  it { is_expected.to have_many(:cart_selections).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:query) }

  describe "normalização da query" do
    it "converte para minúsculas" do
      item = create(:cart_item, query: "Paracetamol")
      expect(item.query).to eq("paracetamol")
    end

    it "remove espaços extras" do
      item = create(:cart_item, query: "  paracetamol  ")
      expect(item.query).to eq("paracetamol")
    end

    it "reutiliza CartItem para a mesma query com capitalização diferente" do
      cart = create(:cart)
      cart.cart_items.find_or_create_by!(query: "Paracetamol")
      expect { cart.cart_items.find_or_create_by!(query: "paracetamol") }
        .not_to change(CartItem, :count)
    end
  end

  describe "#selection_for" do
    let(:item) { create(:cart_item) }

    it "retorna a seleção da farmácia informada" do
      selection = create(:cart_selection, cart_item: item, pharmacy_slug: "paguemenos")
      expect(item.selection_for("paguemenos")).to eq(selection)
    end

    it "retorna nil quando não há seleção para a farmácia" do
      expect(item.selection_for("paguemenos")).to be_nil
    end
  end

  describe "#ideal_selection" do
    let(:item) { create(:cart_item) }

    it "retorna a seleção com menor preço" do
      create(:cart_selection, cart_item: item, pharmacy_slug: "paguemenos", preco: 12.90)
      cheaper = create(:cart_selection, cart_item: item, pharmacy_slug: "rosario", preco: 11.50)
      expect(item.ideal_selection).to eq(cheaper)
    end

    it "retorna nil quando não há seleções" do
      expect(item.ideal_selection).to be_nil
    end
  end
end
