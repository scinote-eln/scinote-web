# frozen_string_literal: true

FactoryBot.define do
  factory :table do
    name { Faker::Name.unique.name }
    contents { { some_data: 'needs to be here' } }
  end
end
