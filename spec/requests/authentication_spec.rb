require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:user) { create(:user, password: "password123") }

  describe "rotas protegidas" do
    before { user }  # garante que existe um usuário (setup já foi feito)

    it "redireciona para login quando não autenticado" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /login" do
    it "autentica com credenciais válidas e redireciona" do
      post user_session_path, params: { user: { email: user.email, password: "password123" } }
      expect(response).to redirect_to(root_path)
    end

    it "limpa o cart_id da sessão ao logar" do
      post user_session_path, params: { user: { email: user.email, password: "password123" } }
      post cart_selections_path, params: {
        query: "dipirona", pharmacy_slug: "paguemenos", pharmacy_name: "Pague Menos",
        nome: "Dipirona 500mg", preco: "9.90", url: "https://exemplo.com", imagem: "", fabricante: "", preco_original: "", sku_id: "", promocao: ""
      }
      expect(session[:cart_id]).to be_present
      delete destroy_user_session_path
      post user_session_path, params: { user: { email: user.email, password: "password123" } }
      expect(session[:cart_id]).to be_nil
    end

    it "rejeita credenciais inválidas" do
      post user_session_path, params: { user: { email: user.email, password: "errada" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /logout" do
    before { post user_session_path, params: { user: { email: user.email, password: "password123" } } }

    it "encerra a sessão e redireciona para login" do
      delete destroy_user_session_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "limpa o cart_id da sessão no logout" do
      post cart_selections_path, params: {
        query: "dipirona", pharmacy_slug: "paguemenos", pharmacy_name: "Pague Menos",
        nome: "Dipirona 500mg", preco: "9.90", url: "https://exemplo.com", imagem: "", fabricante: "", preco_original: "", sku_id: "", promocao: ""
      }
      expect(session[:cart_id]).to be_present
      delete destroy_user_session_path
      expect(session[:cart_id]).to be_nil
    end

    it "redireciona para o issuer configurado quando JWT está presente" do
      allow(HostedInstanceConfig).to receive(:cloudflare_access_logout_url)
        .and_return("https://team.cloudflareaccess.com/cdn-cgi/access/logout")

      delete destroy_user_session_path, headers: { "Cf-Access-Jwt-Assertion" => "token.qualquer.coisa" }
      expect(response).to have_http_status(:see_other)
      expect(response.location).to eq("https://team.cloudflareaccess.com/cdn-cgi/access/logout")
    end

    it "usa o logout local quando o issuer não está configurado" do
      allow(HostedInstanceConfig).to receive(:cloudflare_access_logout_url).and_return(nil)

      delete destroy_user_session_path, headers: { "Cf-Access-Jwt-Assertion" => "token.qualquer.coisa" }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
