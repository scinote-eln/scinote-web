# frozen_string_literal: true

FactoryBot.define do
  factory :repository_date_time_range_value_base do
    created_by { create :user }
    last_modified_by { created_by }
    start_time { Time.zone.now }
    end_time { Faker::Time.between(from: start_time, to: Time.zone.now + 3.days) }
  end

  factory :repository_date_time_range_value,
          parent: :repository_date_time_range_value_base,
          class: 'RepositoryDateTimeRangeValue' do
    after(:build) do |value|
      value.repository_cell ||= build(:repository_cell, :date_time_range_value, repository_date_time_range_value: value)
    end
  end

  factory :repository_time_range_value,
          parent: :repository_date_time_range_value_base,
          class: 'RepositoryTimeRangeValue' do
    after(:build) do |value|
      value.repository_cell ||= build(:repository_cell, :time_range_value, repository_time_range_value: value)
    end
  end

  factory :repository_date_range_value,
          parent: :repository_date_time_range_value_base,
          class: 'RepositoryDateRangeValue' do
    after(:build) do |value|
      value.repository_cell ||= build(:repository_cell, :date_range_value, repository_date_range_value: value)
    end
  end
end
