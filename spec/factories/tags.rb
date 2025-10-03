# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "My tag-#{n}" }
    team
    created_by { association :user }
    color { Faker::Color.hex_color }
  end
end
