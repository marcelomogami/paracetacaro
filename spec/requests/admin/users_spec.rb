require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin)  { create(:user) }
  let(:other)  { create(:user) }
  let(:target) { create(:user, name: "Usuário Exemplo", email: "target@example.com") }

  describe "GET /cadastro" do
    context "quando não autenticado" do
      before { admin }

      it "redireciona para login" do
        get cadastro_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "quando autenticado como admin (primeiro usuário)" do
      before { login_as(admin) }

      it "renderiza o formulário" do
        get cadastro_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "quando autenticado como não-admin" do
      before do
        admin
        login_as(other)
      end

      it "redireciona para root" do
        get cadastro_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /cadastro" do
    context "como admin com dados válidos" do
      before { login_as(admin) }

      it "cria o usuário e redireciona" do
        expect {
          post cadastro_path, params: { user: { email: "novo@example.com", password: "senha123", password_confirmation: "senha123" } }
        }.to change(User, :count).by(1)
        expect(response).to redirect_to(root_path)
      end
    end

    context "como admin com dados inválidos" do
      before { login_as(admin) }

      it "não cria e renderiza o formulário" do
        expect {
          post cadastro_path, params: { user: { email: "invalido", password: "senha123", password_confirmation: "senha123" } }
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "como não-admin" do
      before do
        admin
        login_as(other)
      end

      it "não cria e redireciona para root" do
        expect {
          post cadastro_path, params: { user: { email: "novo@example.com", password: "senha123", password_confirmation: "senha123" } }
        }.not_to change(User, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/users" do
    context "como admin" do
      before do
        login_as(admin)
        target
      end

      it "lista os usuários" do
        get admin_users_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Usuário Exemplo")
        expect(response.body).to include("target@example.com")
      end
    end

    context "como não-admin" do
      before do
        admin
        login_as(other)
      end

      it "redireciona para root" do
        get admin_users_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    context "como admin" do
      before { login_as(admin) }

      it "renderiza o formulário de edição" do
        get edit_admin_user_path(target)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Usuário Exemplo")
        expect(response.body).to include("beta_tester")
      end
    end
  end

  describe "PATCH /admin/users/:id" do
    context "como admin" do
      before { login_as(admin) }

      it "atualiza nome e beta_tester" do
        patch admin_user_path(target), params: { user: { name: "Usuário Atualizado", beta_tester: true } }
        expect(response).to redirect_to(admin_users_path)
        target.reload
        expect(target.name).to eq("Usuário Atualizado")
        expect(target.beta_tester).to be(true)
      end
    end
  end

  describe "DELETE /admin/users/:id" do
    context "como admin" do
      before { login_as(admin) }

      it "remove o usuário" do
        target
        expect {
          delete admin_user_path(target)
        }.to change(User, :count).by(-1)
        expect(response).to redirect_to(admin_users_path)
      end
    end
  end
end
