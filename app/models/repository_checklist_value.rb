# frozen_string_literal: true

class RepositoryChecklistValue < ApplicationRecord
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User',
             inverse_of: :created_repository_checklist_values
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User',
             inverse_of: :modified_repository_checklist_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  SORTABLE_COLUMN_NAME = 'repository_checklistitems'
  SORTABLE_VALUE_INCLUDE = { repository_checklist_value: :repository_checklist_items }.freeze

  def formatted
    data
  end

  def data
    repository_cell.repository_column.repository_checklist_items
                   .where(id: repository_checklist_items).select(:id, :data)
  end
end
