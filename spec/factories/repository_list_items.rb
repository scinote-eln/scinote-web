# frozen_string_literal: true

FactoryBot.define do
  factory :repository_list_item do
    data { Faker::Lorem.paragraph }
    repository_column { create :repository_column, :list_type }
    created_by { create :user }
    last_modified_by { created_by }

    after(:create) do |item|
      item.repository_column.reload
    end
  end
end
