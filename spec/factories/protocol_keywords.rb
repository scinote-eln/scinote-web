# frozen_string_literal: true

FactoryBot.define do
  factory :protocol_keyword do
    name { Faker::Name.unique.name }
    team
  end
end
