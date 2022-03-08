class RepositoryDateValue < ApplicationRecord
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User',
             optional: true
  has_one :repository_cell, as: :value, dependent: :destroy
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true
  validates :data,
            presence: true

  def formatted
    data
  end
end
