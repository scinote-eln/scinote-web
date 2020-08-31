# frozen_string_literal: true

FactoryBot.define do
  factory :sample_group do
    name { Faker::Name.unique.name }
    color { Faker::Color.hex_color }
    team
  end
end
