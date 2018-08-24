class RepositoryListValue < ApplicationRecord
  belongs_to :repository_list_item,
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
    data.to_s
  end

  def data
    return nil unless repository_list_item
    repository_list_item.data
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.repository_list_item = value.repository_cell
                                      .repository_column
                                      .repository_list_items
                                      .find(payload)
    value
  end
end
