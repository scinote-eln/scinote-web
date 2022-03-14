# frozen_string_literal: true

class RepositoryStatusItem < ApplicationRecord
  validates :repository_column, :icon, presence: true
  validates :status, presence: true, length: { minimum: Constants::NAME_MIN_LENGTH,
                                               maximum: Constants::NAME_MAX_LENGTH }
  belongs_to :repository_column
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true,
             inverse_of: :created_repository_status_types
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true,
             inverse_of: :modified_repository_status_types
  has_many :repository_status_values, inverse_of: :repository_status_item, dependent: :destroy

  before_destroy :update_table_fiter_elements

  def data
    "#{icon} #{status}"
  end

  private

  def update_table_fiter_elements
    repository_column.repository_table_filter_elements.find_each do |filter_element|
      filter_element.parameters['item_ids']&.delete(id.to_s)
      filter_element.parameters['item_ids'].blank? ? filter_element.destroy! : filter_element.save!
    end
  end
end
