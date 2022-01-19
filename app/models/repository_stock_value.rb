# frozen_string_literal: true

class RepositoryStockValue < ApplicationRecord
  belongs_to :created_by, class_name: 'User', optional: true, inverse_of: :created_repository_stock_values
  belongs_to :last_modified_by, class_name: 'User', optional: true, inverse_of: :modified_repository_stock_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  has_many :repository_ledger_records, dependent: :destroy
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, presence: true

  SORTABLE_COLUMN_NAME = 'repository_stock_values.amount'

  def formatted
    "#{amount} #{units}"
  end

  def amount_changed?(new_amount)
    BigDecimal(new_amount.to_s) != data
  end

  def update_amount!(new_amount, user)
    self.amount = BigDecimal(new_amount.to_s)
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

  def data
    amount
  end

  def self.new_with_payload(payload, attributes)
    value = new(attributes)
    value.amount = payload
    value
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
