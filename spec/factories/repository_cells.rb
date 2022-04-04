# frozen_string_literal: true

FactoryBot.define do
  factory :repository_cell do
    repository_row

    trait :text_value do
      repository_column { create :repository_column, :text_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= create(:repository_text_value, repository_cell: repository_cell)
      end
    end

    trait :date_time_value do
      repository_column { create :repository_column, :date_time_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_date_time_value, repository_cell: repository_cell)
      end
    end

    trait :time_value do
      repository_column { create :repository_column, :time_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_time_value, repository_cell: repository_cell)
      end
    end

    trait :date_value do
      repository_column { create :repository_column, :date_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_date_value, repository_cell: repository_cell)
      end
    end

    trait :list_value do
      repository_column { create :repository_column, :list_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_list_value, repository_cell: repository_cell)
      end
    end

    trait :asset_value do
      repository_column { create :repository_column, :asset_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_asset_value, repository_cell: repository_cell)
      end
    end

    trait :status_value do
      repository_column { create :repository_column, :status_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_status_value, repository_cell: repository_cell)
      end
    end

    trait :date_time_range_value do
      repository_column { create :repository_column, :date_time_range_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_date_time_range_value, repository_cell: repository_cell)
      end
    end

    trait :date_range_value do
      repository_column { create :repository_column, :date_range_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_date_range_value, repository_cell: repository_cell)
      end
    end

    trait :time_range_value do
      repository_column { create :repository_column, :time_range_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_time_range_value, repository_cell: repository_cell)
      end
    end

    trait :checkbox_value do
      repository_column { create :repository_column, :checklist_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_checklist_value, repository_cell: repository_cell)
      end
    end

    trait :stock_value do
      repository_column { create :repository_column, :stock_type, repository: repository_row.repository }
      after(:build) do |repository_cell|
        repository_cell.value ||= build(:repository_stock_value, repository_cell: repository_cell)
      end
    end
  end
end
