# frozen_string_literal: true

FactoryBot.define do
  factory :repository_checklist_value do
    created_by { create :user }
    last_modified_by { created_by }
    repository_checklist_items { [] }
  end
end
