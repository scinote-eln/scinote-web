# frozen_string_literal: true

FactoryBot.define do
  factory :result_template do
    name { Faker::Name.unique.name }
    user
    protocol
  end
end
