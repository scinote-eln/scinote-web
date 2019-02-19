# frozen_string_literal: true

FactoryBot.define do
  factory :user_system_notification do
    user
    system_notification
    trait :seen do
      seen_at { Faker::Time.between(3.days.ago, Date.today) }
    end
    trait :read do
      read_at { Faker::Time.between(3.days.ago, Date.today) }
    end
    trait :seen_and_read do
      seen_at { Faker::Time.between(3.days.ago, Date.today) }
      read_at { Faker::Time.between(seen_at, Date.today) }
    end
  end
end
