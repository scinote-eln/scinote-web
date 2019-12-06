# frozen_string_literal: true

FactoryBot.define do
  factory :repository_date_time_value_base do
    created_by { create :user }
    last_modified_by { created_by }
    data { Time.zone.now }
  end

  factory :repository_date_time_value, parent: :repository_date_time_value_base, class: 'RepositoryDateTimeValue' do
    after(:build) do |value|
      value.repository_cell ||= build(:repository_cell, :date_time_value, repository_date_time_value: value)
    end
  end
end
