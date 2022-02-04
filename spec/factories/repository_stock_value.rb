# frozen_string_literal: true

FactoryBot.define do
  factory :repository_stock_value do
    created_by { create :user }
    last_modified_by { created_by }
    after(:build) do |repository_stock_value|
      repository_stock_value.repository_cell ||= build(:repository_cell,
                                                       :repository_stock_value,
                                                       repository_stock_value: repository_stock_value)
      repository_stock_value.repository_cell.value = repository_stock_value
    end
  end
end
