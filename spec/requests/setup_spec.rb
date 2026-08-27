require "rails_helper"

RSpec.describe "Setup", type: :request do
  describe "GET /setup" do
    context "sem usuário cadastrado" do
      it "renderiza o formulário" do
        get setup_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "com usuário já cadastrado" do
      before { create(:user) }

      it "redireciona para login" do
        get setup_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /setup" do
    # Params aninhados em user[...] — é como o form_with model: @user envia.
    def user_params(email:, password: "senha123", confirmation: "senha123")
      { user: { email: email, password: password, password_confirmation: confirmation } }
    end

    context "sem usuário cadastrado" do
      it "cria o primeiro usuário" do
        expect {
          post setup_path, params: user_params(email: "admin@example.com")
        }.to change(User, :count).by(1)
      end

      it "faz login automaticamente e redireciona para root" do
        post setup_path, params: user_params(email: "admin@example.com")
        expect(response).to redirect_to(root_path)
      end

      it "rejeita e-mail inválido" do
        post setup_path, params: user_params(email: "invalido")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(User.count).to eq(0)
      end

      it "rejeita confirmação de senha divergente" do
        post setup_path, params: user_params(email: "admin@example.com", confirmation: "diferente")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(User.count).to eq(0)
      end
    end

    context "com usuário já cadastrado" do
      before { create(:user) }

      it "não cria segundo usuário e redireciona para login" do
        expect {
          post setup_path, params: user_params(email: "outro@example.com")
        }.not_to change(User, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
