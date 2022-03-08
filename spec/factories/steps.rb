# frozen_string_literal: true

FactoryBot.define do
  factory :step do
    name { Faker::Name.unique.name }
    position { Faker::Number.between(1, 10) }
    completed { true }
    user
    protocol
    completed_on { Time.now }
  end
end
