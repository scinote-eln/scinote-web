# frozen_string_literal: true

FactoryBot.define do
  factory :repository_list_item do
    data { Faker::Lorem.paragraph }
    repository
    repository_column { create :repository_column, :list_type, repository: repository }
    created_by { create :user }
    last_modified_by { created_by }
  end
end
