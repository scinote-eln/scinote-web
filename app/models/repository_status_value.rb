# frozen_string_literal: true

class RepositoryStatusValue < ApplicationRecord
  validates :repository_status_item, presence: true

  belongs_to :repository_status_item
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true,
             inverse_of: :created_repositroy_status_value
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true,
             inverse_of: :modified_repositroy_status_value
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
end
