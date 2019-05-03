FactoryBot.define do
  factory :user_identity do
    uid Faker::Crypto.unique.sha1
    provider Faker::App.unique.name
  end
end
