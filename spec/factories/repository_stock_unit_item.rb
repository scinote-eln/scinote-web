# frozen_string_literal: true

FactoryBot.define do
  factory :repository_stock_unit_item do
    created_by { create :user }
    last_modified_by { created_by }
    repository_column
    data { "l" }
  end
end
