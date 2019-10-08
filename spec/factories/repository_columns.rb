# frozen_string_literal: true

FactoryBot.define do
  factory :repository_column do
    sequence(:name) { |n| "My column-#{n}" }
    created_by { create :user }
    repository
    data_type { :RepositoryTextValue }

    trait :text_type do
      data_type { :RepositoryTextValue }
    end

    trait :date_type do
      data_type { :RepositoryDateValue }
    end

    trait :list_type do
      data_type { :RepositoryListValue }
    end

    trait :asset_type do
      data_type { :RepositoryAssetValue }
    end

    trait :status_type do
      data_type { :RepositoryStatusValue }
    end
  end
end
