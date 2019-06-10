# frozen_string_literal: true

FactoryBot.define do
  factory :result_text do
    text { Faker::Lorem.paragraph }
    result
  end
end
