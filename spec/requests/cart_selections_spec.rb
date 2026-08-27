require "rails_helper"

RSpec.describe "CartSelections", type: :request do
  before do
    user = create(:user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  let(:valid_params) do
    {
      query: "paracetamol",
      pharmacy_slug: "paguemenos",
      pharmacy_name: "Pague Menos",
      nome: "Paracetamol 500mg 20 Comprimidos",
      preco: "8.90",
      url: "https://www.paguemenos.com.br/paracetamol",
      imagem: "",
      fabricante: "Medley",
      preco_original: "12.50",
      sku_id: "12345678"
    }
  end

  describe "POST /cart_selections" do
    it "cria CartItem e CartSelection" do
      expect {
        post cart_selections_path, params: valid_params
      }.to change(CartItem, :count).by(1).and change(CartSelection, :count).by(1)
    end

    it "reutiliza CartItem para a mesma query independente de maiúsculas" do
      post cart_selections_path, params: valid_params.merge(query: "Paracetamol")
      expect {
        post cart_selections_path, params: valid_params.merge(query: "PARACETAMOL",
          pharmacy_slug: "rosario", pharmacy_name: "Rosário")
      }.to change(CartSelection, :count).by(1)
      expect(CartItem.count).to eq(1)
    end

    it "reutiliza CartItem para a mesma query" do
      post cart_selections_path, params: valid_params
      expect {
        post cart_selections_path, params: valid_params.merge(
          pharmacy_slug: "rosario", pharmacy_name: "Rosário"
        )
      }.to change(CartSelection, :count).by(1)
      expect(CartItem.count).to eq(1)
    end

    it "substitui seleção existente da mesma farmácia" do
      post cart_selections_path, params: valid_params
      expect {
        post cart_selections_path, params: valid_params.merge(nome: "Paracetamol Genérico", preco: "5.90")
      }.not_to change(CartSelection, :count)
      expect(CartSelection.last.nome).to eq("Paracetamol Genérico")
    end

    it "persiste fabricante e preco_original" do
      post cart_selections_path, params: valid_params
      selection = CartSelection.last
      expect(selection.fabricante).to eq("Medley")
      expect(selection.preco_original).to eq(12.50)
    end

    it "aceita fabricante e preco_original ausentes" do
      post cart_selections_path, params: valid_params.except(:fabricante, :preco_original)
      selection = CartSelection.last
      expect(selection.fabricante).to be_nil
      expect(selection.preco_original).to be_nil
    end

    it "persiste sku_id" do
      post cart_selections_path, params: valid_params
      expect(CartSelection.last.sku_id).to eq("12345678")
    end

    it "persiste o cart_id na sessão" do
      post cart_selections_path, params: valid_params
      post cart_selections_path, params: valid_params.merge(query: "ibuprofeno")
      expect(Cart.count).to eq(1)
    end
  end

  describe "DELETE /cart_selections/:id" do
    let!(:selection) do
      post cart_selections_path, params: valid_params
      CartSelection.last
    end

    it "remove a seleção" do
      expect {
        delete cart_selection_path(selection)
      }.to change(CartSelection, :count).by(-1)
    end
  end
end
