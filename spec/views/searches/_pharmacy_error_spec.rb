require "rails_helper"

RSpec.describe "searches/_pharmacy_error", type: :view do
  before do
    render partial: "searches/pharmacy_error",
           locals: { pharmacy_slug: "drogasil", error: "conexão recusada" }
  end

  it "inclui o id correto para o Turbo Stream substituir" do
    expect(rendered).to include('id="pharmacy_drogasil_results"')
  end

  it "exibe a mensagem de erro" do
    expect(rendered).to include("conexão recusada")
  end
end
