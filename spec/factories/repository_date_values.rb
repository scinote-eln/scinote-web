# frozen_string_literal: true

FactoryBot.define do
  factory :repository_date_value do
    created_by { create :user }
    last_modified_by { created_by }
    data { Time.now }
    after(:build) do |repository_date_value|
      repository_date_value.repository_cell ||= build(:repository_cell,
                                                      :date_value,
                                                      repository_date_value: repository_date_value)
    end
  end
end
