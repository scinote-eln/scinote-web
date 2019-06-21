# frozen_string_literal: true

FactoryBot.define do
  factory :sample_type do
    name { Faker::Name.unique.name }
    team
  end
end
