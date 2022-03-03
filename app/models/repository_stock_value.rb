# frozen_string_literal: true

class RepositoryStockValue < ApplicationRecord
  belongs_to :repository_stock_unit_item, optional: true
  belongs_to :created_by, class_name: 'User', optional: true, inverse_of: :created_repository_stock_values
  belongs_to :last_modified_by, class_name: 'User', optional: true, inverse_of: :modified_repository_stock_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  has_many :repository_ledger_records, dependent: :destroy
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true

  SORTABLE_COLUMN_NAME = 'repository_stock_values.amount'

  def formatted
    "#{amount} #{repository_stock_unit_item&.data}"
  end

  def low_stock?
    return false unless low_stock_threshold

    amount <= low_stock_threshold
  end

  def data_changed?(new_data)
    BigDecimal(new_data.to_s) != data
  end

  def update_data!(new_data, user)
    self.amount = BigDecimal(new_data.to_s)
    self.last_modified_by = user
    save!
  end

  def snapshot!(cell_snapshot)
    value_snapshot = dup
    stock_unit_item =
      if repository_stock_unit_item.present?
        cell_snapshot.repository_column
                     .repository_stock_unit_items
                     .find { |item| item.data == repository_stock_unit_item.data }
      end
    value_snapshot.assign_attributes(
      repository_cell: cell_snapshot,
      repository_stock_unit_item: stock_unit_item,
      created_at: created_at,
      updated_at: updated_at
    )
    value_snapshot.save!
  end

  def data
    amount
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.amount = payload
    value
  end

  def self.import_from_text(text, attributes, _options = {})
    digit, unit = text.match(/(^\d*\.?\d*)(\D*)/).captures
    digit.strip!
    unit.strip!
    return nil if digit.blank?

    value = new(attributes.merge(amount: BigDecimal(digit)))
    return value if unit.blank?

    column = attributes.dig(:repository_cell_attributes, :repository_column)
    stock_unit_item = column.repository_stock_unit_items.find { |item| item.data == unit }

    if stock_unit_item.blank?
      stock_unit_item = column.repository_stock_unit_items.new(data: unit,
                                                               created_by: value.created_by,
                                                               last_modified_by: value.last_modified_by)

      return value unless stock_unit_item.save
    end

    value.repository_stock_unit_item = stock_unit_item
    value
  rescue ArgumentError
    nil
  end

  def update_stock_with_ledger!(amount, reference, comment)
    delta = amount.to_d - self.amount.to_d
    repository_ledger_records.create!(
      user: last_modified_by,
      amount: delta,
      balance: amount,
      reference: reference,
      comment: comment
    )
  end

  alias export_formatted formatted
end
