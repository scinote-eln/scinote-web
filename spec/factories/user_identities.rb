# frozen_string_literal: true

FactoryBot.define do
  factory :user_identity do
    user
    uid { Faker::Crypto.unique.sha1 }
    provider { Faker::App.unique.name }
  end
end
