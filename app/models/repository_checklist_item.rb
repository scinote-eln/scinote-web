# frozen_string_literal: true

class RepositoryChecklistItem < ApplicationRecord
  belongs_to :repository_column, inverse_of: :repository_checklist_items
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User',
             inverse_of: :created_repository_checklist_types
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User',
             inverse_of: :modified_repository_checklist_types
  has_many :repository_checklist_items_values, dependent: :destroy
  has_many :repository_checklist_values, through: :repository_checklist_items_values, dependent: :destroy

  validate :validate_per_column_limit
  validates :data, presence: true,
                   uniqueness: { scope: :repository_column_id },
                   length: { maximum: Constants::NAME_MAX_LENGTH }

  before_destroy :update_table_fiter_elements

  private

  def validate_per_column_limit
    if repository_column &&
       repository_column.repository_checklist_items.size > Constants::REPOSITORY_CHECKLIST_ITEMS_PER_COLUMN
      errors.add(:base, :per_column_limit)
    end
  end

  def update_table_fiter_elements
    repository_column.repository_table_filter_elements.find_each do |filter_element|
      filter_element.parameters['item_ids']&.delete(id.to_s)
      filter_element.parameters['item_ids'].blank? ? filter_element.destroy! : filter_element.save!
    end
  end
end
