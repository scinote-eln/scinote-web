class RepositoryListItem < ApplicationRecord
  belongs_to :repository_list_value
  validates :name,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }
end
