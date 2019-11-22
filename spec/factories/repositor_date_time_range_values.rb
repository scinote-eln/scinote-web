# frozen_string_literal: true

FactoryBot.define do
  factory :repository_date_time_range_value do
    created_by { create :user }
    last_modified_by { created_by }
    start_time { Time.zone.now }
    end_time { Faker::Time.between(from: start_time, to: Time.zone.now + 3.days) }

    after(:build) do |value|
      value.repository_cell ||= build(:repository_cell, :date_time_range_value, repository_date_time_range_value: value)
    end
  end
end
