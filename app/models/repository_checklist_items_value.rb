# frozen_string_literal: true

class RepositoryChecklistItemsValue < ApplicationRecord
  belongs_to :repository_checklist_item
  belongs_to :repository_checklist_value, inverse_of: :repository_checklist_items_values

  validates :repository_checklist_item, :repository_checklist_value, presence: true

  after_commit :touch_repository_checklist_value

  private

  # rubocop:disable Rails/SkipsModelValidations
  def touch_repository_checklist_value
    # check if value was deleted, if so, touch repositroy_row directly
    if RepositoryChecklistValue.exists?(repository_checklist_value.id)
      repository_checklist_value.touch
    elsif RepositoryRow.exists?(repository_checklist_value.repository_cell.repository_row.id)
      repository_checklist_value.repository_cell.repository_row.touch
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
