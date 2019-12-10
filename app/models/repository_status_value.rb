# frozen_string_literal: true

class RepositoryStatusValue < ApplicationRecord
  belongs_to :repository_status_item
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true,
             inverse_of: :created_repository_status_value
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true,
             inverse_of: :modified_repository_status_value
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_status_item, presence: true

  SORTABLE_COLUMN_NAME = 'repository_status_items.status'
  SORTABLE_VALUE_INCLUDE = { repository_status_value: :repository_status_item }.freeze

  def formatted
    data
  end

  def data
    return nil unless repository_status_item

    "#{repository_status_item.icon} #{repository_status_item.status}"
  end
end
