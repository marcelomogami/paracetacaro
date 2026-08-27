FactoryBot.define do
  factory :cart_selection do
    cart_item
    pharmacy_slug { "paguemenos" }
    pharmacy_name { "Pague Menos" }
    nome { "Paracetamol 500mg 20 Comprimidos" }
    preco { 8.90 }
    url { "https://www.paguemenos.com.br/paracetamol" }
    imagem { nil }
  end
end
