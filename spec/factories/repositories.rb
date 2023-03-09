# frozen_string_literal: true

FactoryBot.define do
  factory :repository do
    sequence(:name) { |n| "My repository-#{n}" }
    created_by { create :user }
    team { association :team, created_by: created_by }
    trait :write_shared do
      permission_level { :shared_write }
    end
    trait :read_shared do
      permission_level { :shared_read }
    end
    trait :archived do
      archived { true }
      archived_on { Time.zone.now }
      archived_by { created_by }
    end
  end
end
