# frozen_string_literal: true

FactoryBot.define do
  factory :user_system_notification do
    user
    system_notification
    trait :seen do
      seen_at { Faker::Time.between(from: 3.days.ago, to: Date.today) }
    end
    trait :read do
      read_at { Faker::Time.between(from: 3.days.ago, to: Date.today) }
    end
    trait :seen_and_read do
      seen_at { Faker::Time.between(from: 3.days.ago, to: Date.today) }
      read_at { Faker::Time.between(from: seen_at, to: Date.today) }
    end
  end
end
