class RepositoryListItem < ApplicationRecord
  has_many :repository_list_values, inverse_of: :repository_list_item
  belongs_to :repository, inverse_of: :repository_list_items
  belongs_to :repository_column, inverse_of: :repository_list_items
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User'
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User'
  validates :data,
            presence: true,
            uniqueness: { scope: :repository_column, case_sensitive: false },
            length: { maximum: Constants::TEXT_MAX_LENGTH }
end
