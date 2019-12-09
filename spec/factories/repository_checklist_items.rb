# frozen_string_literal: true

FactoryBot.define do
  factory :repository_checklist_item do
    data { Faker::Lorem.paragraph }
    repository
    repository_column { create :repository_column, :checklist_type, repository: repository }
    created_by { create :user }
    last_modified_by { created_by }
  end
end
