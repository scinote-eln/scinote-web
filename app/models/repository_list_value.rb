# frozen_string_literal: true

class RepositoryListValue < ApplicationRecord
  belongs_to :repository_list_item
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User'
  belongs_to :last_modified_by,
             foreign_key: :last_modified_by_id,
             class_name: 'User'
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true
  validates :repository_list_item, presence: true

  validates_inclusion_of :repository_list_item,
                         in: (lambda do |list_value|
                           list_value.repository_cell&.repository_column&.repository_list_items || []
                         end)

  SORTABLE_COLUMN_NAME = 'repository_list_items.data'
  SORTABLE_VALUE_INCLUDE = { repository_list_value: :repository_list_item }.freeze
  PRELOAD_INCLUDE = { repository_list_value: :repository_list_item }.freeze

  def formatted
    data.to_s
  end

  def data
    return nil unless repository_list_item
    repository_list_item.data
  end

  def data_changed?(new_data)
    new_data.to_i != repository_list_item_id
  end

  def update_data!(new_data, user)
    self.repository_list_item_id = new_data.to_i
    self.last_modified_by = user
    save!
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.repository_list_item = value.repository_cell
                                      .repository_column
                                      .repository_list_items
                                      .find(payload)
    value
  end

  def self.import_from_text(text, attributes)
    value = new(attributes)
    column = attributes.dig(:repository_cell_attributes, :repository_column)
    list_item = column.repository_list_items.find { |item| item.data == text }

    if list_item.blank?
      list_item = column.repository_list_items.new(data: text,
                                                   created_by: value.created_by,
                                                   last_modified_by: value.last_modified_by,
                                                   repository: column.repository)

      return nil unless list_item.save
    end

    value.repository_list_item = list_item
    value
  end

  alias export_formatted formatted
end
