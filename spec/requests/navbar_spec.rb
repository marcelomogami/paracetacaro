require "rails_helper"

RSpec.describe "Navbar", type: :request do
  let(:user) { create(:user) }
  let(:beta_user) { create(:user, :beta_tester) }

  before { user }

  def sign_in_as(u)
    post user_session_path, params: { user: { email: u.email, password: "password123" } }
  end

  describe "menu de usuário" do
    it "exibe o nome do usuário logado" do
      sign_in_as(user)
      get root_path
      expect(response.body).to include(user.name)
    end

    it "não exibe badge Beta para usuário comum" do
      sign_in_as(user)
      get root_path
      expect(response.body).not_to include("Beta")
    end

    it "exibe badge Beta para usuário beta_tester" do
      sign_in_as(beta_user)
      get root_path
      expect(response.body).to include("Beta")
    end

    it "exibe link de logout" do
      sign_in_as(user)
      get root_path
      expect(response.body).to include(destroy_user_session_path)
    end
  end
end
