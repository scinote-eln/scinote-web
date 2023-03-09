# frozen_string_literal: true

FactoryBot.define do
  factory :repository_column do
    sequence(:name) { |n| "My column-#{n}" }
    created_by { create :user }
    repository { association :repository, created_by: created_by }
    data_type { :RepositoryTextValue }

    trait :text_type do
      data_type { :RepositoryTextValue }
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

    trait :date_time_type do
      data_type { :RepositoryDateTimeValue }
    end

    trait :date_type do
      data_type { :RepositoryDateValue }
    end

    trait :time_type do
      data_type { :RepositoryTimeValue }
    end

    trait :date_time_range_type do
      data_type { :RepositoryDateTimeRangeValue }
    end

    trait :date_range_type do
      data_type { :RepositoryDateRangeValue }
    end

    trait :time_range_type do
      data_type { :RepositoryTimeRangeValue }
    end

    trait :checklist_type do
      data_type { :RepositoryChecklistValue }
    end

    trait :stock_type do
      data_type { :RepositoryStockValue }
    end
  end
end
