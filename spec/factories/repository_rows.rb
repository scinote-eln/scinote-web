# frozen_string_literal: true

FactoryBot.define do
  factory :repository_row do
    sequence(:name) { |n| "My row-#{n}" }
    created_by { create :user }
    repository
    last_modified_by { created_by }

    trait :archived do
      archived { true }
      archived_on { Time.zone.now }
      archived_by { created_by }
    end

    trait :restored do
      archived { false }
      restored_on { Time.zone.now }
      restored_by { created_by }
    end
  end
end
