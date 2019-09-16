# frozen_string_literal: true

FactoryBot.define do
  factory :repository do
    sequence(:name) { |n| "My repository-#{n}" }
    created_by { create :user }
    team
    trait :write_shared do
      permission_level { :shared_write }
    end
    trait :read_shared do
      permission_level { :shared_read }
    end
  end
end
