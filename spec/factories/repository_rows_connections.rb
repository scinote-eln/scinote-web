# frozen_string_literal: true

FactoryBot.define do
  factory :repository_row_connection do
    association :parent, factory: :repository_row
    association :child, factory: :repository_row
    association :created_by, factory: :user
    last_modified_by { created_by }
  end
end
