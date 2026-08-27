FactoryBot.define do
  factory :cart do
    name { "Carrinho #{Time.current.strftime('%d/%m/%Y')}" }
  end
end
