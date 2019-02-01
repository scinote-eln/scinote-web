# frozen_string_literal: true

FactoryBot.define do
  factory :user_system_notification do
    user
    system_notification
    trait :seen do
      seen { Faker::Time.between(3.days.ago, Date.today) }
    end
    trait :read do
      read { Faker::Time.between(3.days.ago, Date.today) }
    end
    trait :seen_and_read do
      seen { Faker::Time.between(3.days.ago, Date.today) }
      read { Faker::Time.between(seen, Date.today) }
    end
  end
end
