# frozen_string_literal: true

class RepositoryChecklistValue < ApplicationRecord
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User',
                          inverse_of: :created_repository_checklist_values
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User',
                                inverse_of: :modified_repository_checklist_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  has_many :repository_checklist_items_values, dependent: :destroy
  has_many :repository_checklist_items, -> { order('data ASC') }, through: :repository_checklist_items_values
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true
  validates :repository_checklist_items, presence: true

  SORTABLE_COLUMN_NAME = 'repository_checklist_items.data'
  SORTABLE_VALUE_INCLUDE = { repository_checklist_value: :repository_checklist_items }.freeze
  PRELOAD_INCLUDE = { repository_checklist_value: :repository_checklist_items }.freeze

  def formatted(separator: ' | ')
    repository_checklist_items.pluck(:data).join(separator)
  end

  def export_formatted
    repository_checklist_items.pluck(:data).map { |d| d.tr("\n", ' ') }.join("\n")
  end

  def data
    repository_checklist_items.map { |i| { value: i.id, label: i.data } }
  end

  def data_changed?(new_data)
    JSON.parse(new_data) != repository_checklist_items.pluck(:id)
  end

  def update_data!(new_data, user)
    item_ids = JSON.parse(new_data)
    return destroy! if item_ids.blank?

    self.repository_checklist_items = repository_cell.repository_column
                                                     .repository_checklist_items
                                                     .where(id: item_ids)
    self.last_modified_by = user
    save!
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.repository_checklist_items = value.repository_cell
                                            .repository_column
                                            .repository_checklist_items
                                            .where(id: JSON.parse(payload))
    value
  end

  def self.import_from_text(text, attributes)
    value = new(attributes)
    column = attributes.dig(:repository_cell_attributes, :repository_column)
    text.split("\n").each do |item_text|
      checklist_item = column.repository_checklist_items.find { |item| item.data == item_text }

      if checklist_item.blank?
        checklist_item = column.repository_checklist_items.new(data: text,
                                                               created_by: value.created_by,
                                                               last_modified_by: value.last_modified_by,
                                                               repository: column.repository)

        return nil unless checklist_item.save
      end

      value.repository_checklist_items << checklist_item
    end

    value
  end
end
