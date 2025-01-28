# frozen_string_literal: true

FactoryBot.define do
  factory :form do
    name { Faker::Name.unique.name }
    description { Faker::Lorem.sentence }
    association :created_by, factory: :user
    association :last_modified_by, factory: :user
    team { create :team, created_by: created_by }
    archived { false }

    trait :archived do
      archived { true }
      archived_on { Time.zone.now }
      archived_by { created_by }
    end
  end
end
