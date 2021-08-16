# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "My project-#{n}" }
    association :created_by, factory: :user
    team { create :team, created_by: created_by }
    archived { false }
    visibility { 'hidden' }

    trait :archived do
      archived { true }
      archived_on { Time.zone.now }
      archived_by { created_by }
    end
  end
end
