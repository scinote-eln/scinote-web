# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    association :created_by, factory: :user
    sequence(:name) { |n| "My team-#{n}" }
    description { Faker::Lorem.sentence }
    space_taken { 1048576 }
  end
end
