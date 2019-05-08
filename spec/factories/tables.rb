# frozen_string_literal: true

FactoryBot.define do
  factory :table do
    name { Faker::Name.unique.name }
    contents { Faker::Lorem.characters }
  end
end
