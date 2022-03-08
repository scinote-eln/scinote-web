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

  def formatted
    data.to_s
  end

  def data_changed?(new_data)
    BigDecimal(new_data.to_s) != data
  end

  def update_data!(new_data, user)
    self.data = BigDecimal(new_data.to_s)
    self.last_modified_by = user
    save!
  end

  def snapshot!(cell_snapshot)
    value_snapshot = dup
    value_snapshot.assign_attributes(
      repository_cell: cell_snapshot,
      created_at: created_at,
      updated_at: updated_at
    )
    value_snapshot.save!
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.data = BigDecimal(payload.to_s)
    value
  end

  def self.import_from_text(text, attributes, _options = {})
    new(attributes.merge(data: BigDecimal(text.to_s)))
  rescue ArgumentError
    nil
  end

  alias export_formatted formatted
end
