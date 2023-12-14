# frozen_string_literal: true

FactoryBot.define do
  factory :result_text do
    name { Faker::Name.unique.name }
    text { Faker::Lorem.paragraph }
    result
  end
end
