# frozen_string_literal: true

FactoryBot.define do
  factory :token do
    token { Faker::Lorem.characters(number: 100) }
    ttl { 60 }
    user
  end
end
