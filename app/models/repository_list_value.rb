class RepositoryListValue < ApplicationRecord
  has_many :repository_list_items, dependent: :destroy
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User',
             optional: true
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true

  def formatted
    item = repository_list_items.find_by_id(selected_item)
    return '' unless item
    item.name
  end
end
