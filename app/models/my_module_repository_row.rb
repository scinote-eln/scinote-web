class MyModuleRepositoryRow < ApplicationRecord
  belongs_to :assigned_by,
             foreign_key: 'assigned_by_id',
             class_name: 'User',
             optional: true
  belongs_to :repository_row,
             inverse_of: :my_module_repository_rows
  belongs_to :my_module,
             touch: true,
             inverse_of: :my_module_repository_rows

  validates :repository_row, uniqueness: { scope: :my_module }

  around_save :deduct_stock_balance, if: :stock_consumption_changed?

  private

  def deduct_stock_balance
    stock_value = repository_row.repository_stock_value
    delta = stock_consumption_was.to_d - stock_consumption.to_d
    lock!
    stock_value.lock!
    stock_value.amount = stock_value.amount - delta
    yield
    stock_value.save!
    stock_value.repository_ledger_records.create!(user: last_modified_by, amount: delta, balance: stock_value.amount)
    save!
  end
end
