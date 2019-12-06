# frozen_string_literal: true

class RepositoryCheckboxItem < ApplicationRecord
  validates :data, presence: true,
                   uniqueness: { scope: :repository_column_id, case_sensitive: false },
                   length: { minimum: Constants::NAME_MIN_LENGTH,
                             maximum: Constants::NAME_MAX_LENGTH }
  belongs_to :repository, inverse_of: :repository_checklist_items
  belongs_to :repository_column
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true,
             inverse_of: :created_repository_checkbox_types
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true,
             inverse_of: :modified_repository_checkbox_types
end
