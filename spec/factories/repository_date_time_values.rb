# frozen_string_literal: true

FactoryBot.define do
  factory :repository_date_time_value do
    created_by { create :user }
    last_modified_by { created_by }
    data { Time.zone.now }

    after(:build) do |value|
      value.repository_cell ||= build(:repository_cell, :date_time_value, repository_date_time_value: value)
    end
  end
end
