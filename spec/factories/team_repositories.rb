# frozen_string_literal: true

FactoryBot.define do
  factory :team_repository do
    team
    repository
    trait :read do
      permission_level { :read }
    end
    trait :write do
      permission_level { :write }
    end
  end
end
