FactoryBot.define do
  factory :cart_item do
    cart
    query { "paracetamol" }
  end
end
