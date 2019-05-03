# frozen_string_literal: true

FactoryBot.define do
  factory :repository_row do
    sequence(:name) { |n| "My row-#{n}" }
    created_by { create :user }
    repository
    last_modified_by { created_by }
  end
end
