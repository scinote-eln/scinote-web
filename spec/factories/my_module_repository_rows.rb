# frozen_string_literal: true

FactoryBot.define do
  factory :mm_repository_row, class: MyModuleRepositoryRow do
    repository_row
    my_module
    repository_stock_unit_item
  end
end
