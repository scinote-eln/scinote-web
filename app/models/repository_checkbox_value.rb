# frozen_string_literal: true

class RepositoryCheckboxValue < ApplicationRecord
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true,
             inverse_of: :created_repository_checkbox_value
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true,
             inverse_of: :modified_repository_checkbox_value
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  SORTABLE_COLUMN_NAME = 'repository_checkboxes_items'
  SORTABLE_VALUE_INCLUDE = { repository_checkbox_value: :repository_checkbox_items }.freeze

  def formatted
    data
  end

  def data
    repository_cell.repository_column.repository_checkbox_items
                   .where(id: repository_checkboxes_items).select(:id, :data)
  end
end
