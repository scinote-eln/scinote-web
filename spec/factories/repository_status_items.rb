# frozen_string_literal: true

FactoryBot.define do
  factory :repository_status_item do
    sequence(:icon) { |n| "icon-#{n}" }
    sequence(:status) { |n| "status-#{n}" }
    repository
    repository_column
    created_by { create :user }
  end
end
