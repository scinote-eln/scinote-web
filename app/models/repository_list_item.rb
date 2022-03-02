# frozen_string_literal: true

class RepositoryListItem < ApplicationRecord
  has_many :repository_list_values, inverse_of: :repository_list_item, dependent: :destroy
  belongs_to :repository_column, inverse_of: :repository_list_items
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User'
  validate :validate_per_column_limit
  validates :data,
            presence: true,
            uniqueness: { scope: :repository_column_id },
            length: { maximum: Constants::TEXT_MAX_LENGTH }

  before_destroy :update_table_fiter_elements

  private

  def validate_per_column_limit
    if repository_column &&
       repository_column.repository_list_items.size > Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN
      errors.add(:base, :per_column_limit)
    end
  end

  def update_table_fiter_elements
    repository_column.repository_table_filter_elements.find_each do |filter_element|
      filter_element.parameters['item_ids']&.delete(id.to_s)
      filter_element.parameters['item_ids'].blank? ? filter_element.destroy! : filter_element.save!
    end
  end
end
