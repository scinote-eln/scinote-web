# frozen_string_literal: true

FactoryBot.define do
  factory :report do
    user
    project
    team
    name { Faker::Name.unique.name }
    description { Faker::Lorem.sentence }
  end
end
