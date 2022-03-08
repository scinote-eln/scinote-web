# frozen_string_literal: true

FactoryBot.define do
  factory :temp_file do
    session_id { Faker::Lorem.characters(number: 20) }
  end
end
