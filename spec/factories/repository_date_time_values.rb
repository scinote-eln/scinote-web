# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
FactoryBot.define do
  factory :repository_date_time_value do
    created_by { create :user }
    last_modified_by { created_by }
    start_time { Time.zone.now }

    trait :datetime do
      datetime_type { :datetime }
    end

    trait :date do
      datetime_type { :date }
    end

    trait :time do
      datetime_type { :time }
    end

    trait :datetime_range do
      datetime_type { :datetime_range }
      end_time { Faker::Time.between(from: start_time, to: Time.zone.now + 3.days) }
    end

    trait :date_range do
      datetime_type { :date_range }
      end_time { Faker::Time.between(from: start_time, to: Time.zone.now + 3.days) }
    end

    trait :time_range do
      datetime_type { :time_range }
      end_time { Faker::Time.between(from: start_time, to: Time.zone.now + 3.days) }
    end

    after(:build) do |value|
      value.repository_cell ||= build(:repository_cell, :date_time_value, repository_date_time_value: value)
    end
  end
end
# rubocop:enable Metrics/BlockLength
