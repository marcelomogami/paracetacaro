FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }

    trait :beta_tester do
      beta_tester { true }
    end
  end
end
