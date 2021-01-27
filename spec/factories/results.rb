# frozen_string_literal: true

FactoryBot.define do
  factory :result do
    name { Faker::Name.unique.name }
    user
    my_module
    trait :archived do
      archived { true }
      archived_on { Time.zone.now }
      archived_by { user }
    end
  end
end
