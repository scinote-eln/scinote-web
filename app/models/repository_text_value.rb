class RepositoryTextValue < ActiveRecord::Base
  has_one :repository_cell, as: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true
end
