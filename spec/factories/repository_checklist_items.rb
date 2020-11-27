# frozen_string_literal: true

FactoryBot.define do
  factory :repository_checklist_item do
    data { Faker::Lorem.paragraph }
    repository_column { create :repository_column, :checklist_type }
    created_by { create :user }
    last_modified_by { created_by }

    after(:create) do |item|
      item.repository_column.reload
    end
  end
end
