class RepositoryListValue < ApplicationRecord
  belongs_to :selected_item,
             foreign_key: :selected_item_id,
             class_name: 'RepositoryListItem',
             optional: true
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User'
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User'
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true

  def formatted
    return '' unless selected_item
    selected_item.name
  end
end
