# frozen_string_literal: true

class RepositoryTextValue < ApplicationRecord
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User'
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true
  validates :data, presence: true, length: { maximum: Constants::TEXT_MAX_LENGTH }

  SORTABLE_COLUMN_NAME = 'repository_text_values.data'
  SORTABLE_VALUE_INCLUDE = :repository_text_value
  PRELOAD_INCLUDE = :repository_text_value

  def formatted
    data
  end

  def data_changed?(new_data)
    new_data != data
  end

  def update_data!(new_data, user)
    self.data = new_data
    self.last_modified_by = user
    save!
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = payload
    value
  end

  def self.import_from_text(text, attributes)
    return nil if text.blank?

    new(attributes.merge(data: text.truncate(Constants::TEXT_MAX_LENGTH)))
  end

  alias export_formatted formatted
end
