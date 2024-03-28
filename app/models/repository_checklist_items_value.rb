# frozen_string_literal: true

class RepositoryChecklistItemsValue < ApplicationRecord
  belongs_to :repository_checklist_item
  belongs_to :repository_checklist_value, inverse_of: :repository_checklist_items_values

  validates :repository_checklist_item, :repository_checklist_value, presence: true
end
