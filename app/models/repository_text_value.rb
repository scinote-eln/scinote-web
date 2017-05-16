class RepositoryTextValue < ActiveRecord::Base
  has_one :repository_cell, as: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true
  validates :value,
            presence: true,
            length: { maximum: Constants::TEXT_MAX_LENGTH }
end
