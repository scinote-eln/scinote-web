# frozen_string_literal: true

class RepositoryCellValuesChecklistItem < ApplicationRecord
  belongs_to :repository_checklist_item
  belongs_to :repository_checklist_value

  validates :repository_checklist_item, :repository_checklist_value, presence: true
end
