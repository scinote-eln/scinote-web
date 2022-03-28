# frozen_string_literal: true

FactoryBot.define do
  factory :repository_stock_value do
    created_by { create :user }
    last_modified_by { created_by }
    repository_stock_unit_item
    amount { 1000.0 }
    after(:build) do |repository_stock_value|
      repository_stock_value.repository_cell ||= build(:repository_cell,
                                                        :stock_value,
                                                        repository_stock_value: repository_stock_value)
    end
  end
end
