# frozen_string_literal: true

FactoryBot.define do
  factory :repository_stock_unit_item do
    sequence(:data) { |n| "u-#{n}" }
    repository_column
    created_by { create :user }
    last_modified_by { created_by }
  end
end
