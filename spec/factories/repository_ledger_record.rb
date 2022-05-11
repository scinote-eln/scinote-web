# frozen_string_literal: true

FactoryBot.define do
  factory :repository_ledger_record do
    repository_stock_value
    association :reference, factory: :repository_row
    user
  end
end

