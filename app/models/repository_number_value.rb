# frozen_string_literal: true

class RepositoryNumberValue < ApplicationRecord
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User',
             inverse_of: :created_repository_number_values
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User',
             inverse_of: :modified_repository_number_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, :data, presence: true

  SORTABLE_COLUMN_NAME = 'repository_number_values.data'
  SORTABLE_VALUE_INCLUDE = :repository_number_value

  def formatted
    data
  end
end
