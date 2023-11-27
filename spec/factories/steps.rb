# frozen_string_literal: true

FactoryBot.define do
  factory :step do
    name { Faker::Name.unique.name }
    sequence(:position) { |n| n }
    completed { true }
    user
    protocol
    completed_on { Time.now }
  end
end
