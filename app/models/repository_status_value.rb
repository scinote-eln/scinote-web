# frozen_string_literal: true

class RepositoryStatusValue < ApplicationRecord
  belongs_to :repository_status_item
  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true,
             inverse_of: :created_repository_status_value
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true,
             inverse_of: :modified_repository_status_value
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, :repository_status_item, presence: true

  SORTABLE_COLUMN_NAME = 'repository_status_items.status'
  SORTABLE_VALUE_INCLUDE = { repository_status_value: :repository_status_item }.freeze
  PRELOAD_INCLUDE = { repository_status_value: :repository_status_item }.freeze

  def formatted
    data
  end

  def data_changed?(new_data)
    new_data.to_i != repository_status_item_id
  end

  def update_data!(new_data, user)
    self.repository_status_item_id = new_data.to_i
    self.last_modified_by = user
    save!
  end

  def data
    return nil unless repository_status_item

    "#{repository_status_item.icon} #{repository_status_item.status}"
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.repository_status_item = value.repository_cell
                                        .repository_column
                                        .repository_status_items
                                        .find(payload)
    value
  end

  def self.import_from_text(text, attributes)
    icon = text[0]
    status = text[1..-1].strip
    value = new(attributes)
    column = attributes.dig(:repository_cell_attributes, :repository_column)
    status_item = column.repository_status_items.find { |item| item.status == status }

    if status_item.blank?
      status_item = column.repository_status_items.new(icon: icon,
                                                       status: status,
                                                       created_by: value.created_by,
                                                       last_modified_by: value.last_modified_by,
                                                       repository: column.repository)

      return nil unless status_item.save
    end

    value.repository_status_item = status_item
    value
  end

  alias export_formatted formatted
end
