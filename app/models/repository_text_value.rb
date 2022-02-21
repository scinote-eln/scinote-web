# frozen_string_literal: true

class RepositoryTextValue < ApplicationRecord
  belongs_to :created_by, foreign_key: :created_by_id,
                          class_name: 'User',
                          inverse_of: :created_repository_text_values
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id,
                                class_name: 'User',
                                inverse_of: :modified_repository_text_values
  has_one :repository_cell, as: :value, dependent: :destroy
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true
  validates :data, presence: true, length: { maximum: Constants::TEXT_MAX_LENGTH }

  SORTABLE_COLUMN_NAME = 'repository_text_values.data'

  def formatted
    data
  end

  def self.add_filter_condition(repository_rows, join_alias, filter_element)
    case filter_element.operator
    when 'contains'
      repository_rows
        .where("#{join_alias}.data ILIKE ?", "%#{sanitize_sql_like(filter_element.parameters['text'])}%")
    when 'doesnt_contain'
      repository_rows
        .where.not("#{join_alias}.data ILIKE ?", "%#{sanitize_sql_like(filter_element.parameters['text'])}%")
    else
      raise ArgumentError, 'Wrong operator for RepositoryTextValue!'
    end
  end

  def data_different?(new_data)
    new_data != data
  end

  def update_data!(new_data, user)
    self.data = new_data
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
    value.data = payload
    value
  end

  def self.import_from_text(text, attributes, _options = {})
    return nil if text.blank?

    new(attributes.merge(data: text.truncate(Constants::TEXT_MAX_LENGTH)))
  end

  alias export_formatted formatted
end
