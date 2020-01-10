# frozen_string_literal: true

FactoryBot.define do
  factory :repository_checklist_value do
    created_by { create :user }
    last_modified_by { created_by }
    repository_checklist_items { [] }
    after(:build) do |repository_checklist_value|
      repository_checklist_value.repository_cell ||= build(:repository_cell,
                                                           :checkbox_value,
                                                           repository_checklist_value: repository_checklist_value)
    end
  end
end
