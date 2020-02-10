# frozen_string_literal: true

class RepositoryNumberValue < ApplicationRecord
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User',
             inverse_of: :created_repository_number_values
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User',
             inverse_of: :modified_repository_number_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, :data, presence: true

  SORTABLE_COLUMN_NAME = 'repository_number_values.data'
  SORTABLE_VALUE_INCLUDE = :repository_number_value
  PRELOAD_INCLUDE = :repository_number_value

  def formatted
    data.to_s
  end

  def data_changed?(new_data)
    BigDecimal(new_data) != data
  end

  def update_data!(new_data, user)
    self.data = BigDecimal(new_data)
    self.last_modified_by = user
    save!
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = BigDecimal(payload)
    value
  end

  def self.import_from_text(text, attributes)
    new(attributes.merge(data: BigDecimal(text)))
  rescue ArgumentError
    nil
  end

  alias export_formatted formatted
end
