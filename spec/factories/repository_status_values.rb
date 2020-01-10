# frozen_string_literal: true

FactoryBot.define do
  factory :repository_status_value do
    created_by { create :user }
    last_modified_by { created_by }
    repository_status_item
    after(:build) do |repository_status_value|
      repository_status_value.repository_cell ||= build(:repository_cell,
                                                        :status_value,
                                                        repository_status_value: repository_status_value)
    end
  end
end
