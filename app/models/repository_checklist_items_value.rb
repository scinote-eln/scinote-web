# frozen_string_literal: true

class RepositoryChecklistItemsValue < ApplicationRecord
  belongs_to :repository_checklist_item
  belongs_to :repository_checklist_value, inverse_of: :repository_checklist_items_values

  validates :repository_checklist_item, :repository_checklist_value, presence: true

  after_create :touch_repository_checklist_value
  before_destroy :touch_repository_checklist_value

  private

  # rubocop:disable Rails/SkipsModelValidations
  def touch_repository_checklist_value
    repository_checklist_value.touch
  end
  # rubocop:enable Rails/SkipsModelValidations
end
