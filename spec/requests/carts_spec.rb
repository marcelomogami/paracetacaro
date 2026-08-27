require "rails_helper"

RSpec.describe "Carts", type: :request do
  before do
    user = create(:user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  describe "DELETE /cart" do
    it "remove todos os itens e seleções do carrinho" do
      post cart_selections_path, params: {
        query: "paracetamol", pharmacy_slug: "paguemenos", pharmacy_name: "Pague Menos",
        nome: "Paracetamol 500mg", preco: "8.90", url: "https://example.com", imagem: ""
      }
      post cart_selections_path, params: {
        query: "ibuprofeno", pharmacy_slug: "paguemenos", pharmacy_name: "Pague Menos",
        nome: "Ibuprofeno 400mg", preco: "12.90", url: "https://example.com/ibu", imagem: ""
      }
      expect { delete cart_path }.to change(CartItem, :count).by(-2).and change(CartSelection, :count).by(-2)
    end

    it "mantém o carrinho na sessão após limpar" do
      post cart_selections_path, params: {
        query: "paracetamol", pharmacy_slug: "paguemenos", pharmacy_name: "Pague Menos",
        nome: "Paracetamol 500mg", preco: "8.90", url: "https://example.com", imagem: ""
      }
      cart_id = Cart.last.id
      delete cart_path
      expect(session[:cart_id]).to eq(cart_id)
    end
  end

  describe "GET /cart/checkout" do
    let(:pharmacy_config) do
      instance_double(PharmacyConfig, slug: "paguemenos", name: "Pague Menos",
                      enabled?: true, site_url: "https://www.paguemenos.com.br")
    end

    before do
      allow(PharmacyConfig).to receive(:load_all).and_return([ pharmacy_config ])
      post cart_selections_path, params: {
        query: "paracetamol", pharmacy_slug: "paguemenos", pharmacy_name: "Pague Menos",
        nome: "Paracetamol 500mg", preco: "8.90", url: "https://example.com",
        imagem: "", sku_id: "99887766"
      }
    end

    it "redireciona para o cart/add da farmácia com os sku_ids" do
      get checkout_cart_path, params: { pharmacy_slug: "paguemenos" }
      expect(response).to redirect_to(%r{paguemenos\.com\.br/checkout/cart/add.*sku=99887766})
    end

    it "redireciona para o carrinho se não houver itens com sku_id" do
      CartSelection.update_all(sku_id: nil)
      get checkout_cart_path, params: { pharmacy_slug: "paguemenos" }
      expect(response).to redirect_to(cart_path)
    end
  end

  describe "GET /cart" do
    it "renderiza o carrinho vazio" do
      get cart_path
      expect(response).to have_http_status(:ok)
    end

    it "exibe os itens do carrinho da sessão" do
      post cart_selections_path, params: {
        query: "ibuprofeno",
        pharmacy_slug: "paguemenos",
        pharmacy_name: "Pague Menos",
        nome: "Ibuprofeno 400mg 20 Comprimidos",
        preco: "12.90",
        url: "https://www.paguemenos.com.br/ibuprofeno",
        imagem: ""
      }
      get cart_path
      expect(response.body).to include("ibuprofeno")
    end
  end
end
