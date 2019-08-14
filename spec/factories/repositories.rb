# frozen_string_literal: true

FactoryBot.define do
  factory :repository do
    sequence(:name) { |n| "My repository-#{n}" }
    created_by { create :user }
    team
    trait :write_shared do
      shared { true }
      permission_level { :write }
    end
    trait :read_shared do
      shared { true }
      permission_level { :read }
    end
  end
end
