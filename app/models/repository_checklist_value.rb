# frozen_string_literal: true

class RepositoryChecklistValue < ApplicationRecord
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User',
             inverse_of: :created_repository_checklist_values
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User',
             inverse_of: :modified_repository_checklist_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  has_many :repository_cell_values_checklist_items, dependent: :destroy
  has_many :repository_checklist_items, through: :repository_cell_values_checklist_items

  accepts_nested_attributes_for :repository_cell

  SORTABLE_COLUMN_NAME = 'repository_checklist_items.data'
  SORTABLE_VALUE_INCLUDE = { repository_checklist_value: :repository_checklist_items }.freeze

  def formatted
    repository_cell.repository_column.repository_checklist_items
                   .where(id: repository_checklist_items).select(:data).join('\n')
  end

  def data
    repository_checklist_items.order(data: :asc).map { |i| { value: i.id, label: i.data } }
  end

  def data_changed?(new_data)
    JSON.parse(new_data) != repository_checklist_items.pluck(:id)
  end

  def update_data!(new_data, user)
    repository_cell_values_checklist_items.destroy_all
    repository_cell.repository_column
                   .repository_checklist_items.where(id: JSON.parse(new_data)).find_each do |item|
      repository_cell_values_checklist_items.create!(repository_checklist_item: item)
    end
    self.last_modified_by = user
    save!
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.repository_cell
         .repository_column
         .repository_checklist_items.where(id: JSON.parse(payload)).find_each do |item|
      value.repository_cell_values_checklist_items.new(repository_checklist_item: item)
    end
    value
  end
end
