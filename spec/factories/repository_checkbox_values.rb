# frozen_string_literal: true

FactoryBot.define do
  factory :repository_checkbox_value do
    created_by { create :user }
    last_modified_by { created_by }
    repository_checkboxes_items { [] }
  end
end
