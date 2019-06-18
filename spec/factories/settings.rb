# frozen_string_literal: true

FactoryBot.define do
  factory :settings do
    type { Faker::Lorem.sentence.split(' ').sample }
    values { { key_of_data: Faker::Lorem.sentence.split(' ').sample } }
  end
end
