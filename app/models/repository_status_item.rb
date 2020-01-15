# frozen_string_literal: true

class RepositoryStatusItem < ApplicationRecord
  validates :repository, :repository_column, :icon, presence: true
  validates :status, presence: true, length: { minimum: Constants::NAME_MIN_LENGTH,
                                               maximum: Constants::NAME_MAX_LENGTH }
  belongs_to :repository
  belongs_to :repository_column
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true,
             inverse_of: :created_repository_status_types
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true,
             inverse_of: :modified_repository_status_types
  has_many :repository_status_values, inverse_of: :repository_status_item, dependent: :destroy
end
