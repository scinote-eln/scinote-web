# frozen_string_literal: true

FactoryBot.define do
  factory :repository_list_value do
    created_by { create :user }
    last_modified_by { created_by }
    repository_list_item
    after(:build) do |repository_list_value|
      repository_list_value.repository_cell ||= build(:repository_cell,
                                                      :list_value,
                                                      repository_list_value: repository_list_value)

      repository_list_value.repository_cell.repository_column.repository_list_items <<
        repository_list_value.repository_list_item
    end
  end
end
