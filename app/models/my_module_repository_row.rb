class MyModuleRepositoryRow < ApplicationRecord
  attr_accessor :last_modified_by
  attr_accessor :comment

  belongs_to :assigned_by,
             foreign_key: 'assigned_by_id',
             class_name: 'User',
             optional: true
  belongs_to :repository_row,
             inverse_of: :my_module_repository_rows
  belongs_to :my_module,
             touch: true,
             inverse_of: :my_module_repository_rows
  belongs_to :repository_stock_unit_item, optional: true

  validates :repository_row, uniqueness: { scope: :my_module }

  before_save :nulify_stock_consumption, if: :stock_consumption_changed?
  around_save :deduct_stock_balance, if: :stock_consumption_changed?

  def consume_stock(user, stock_consumption, comment = nil)
    ActiveRecord::Base.transaction(requires_new: true) do
      lock!
      assign_attributes(
        stock_consumption: stock_consumption,
        repository_stock_unit_item_id:
          repository_row.repository_stock_value.repository_stock_unit_item_id,
        last_modified_by: user,
        comment: comment
      )
      save!
    end
  end

  private

  def nulify_stock_consumption
    self.stock_consumption = nil if stock_consumption.zero?
  end

  def deduct_stock_balance
    stock_value = repository_row.repository_stock_value
    stock_value.lock!
    delta = stock_consumption.to_d - stock_consumption_was.to_d
    stock_value.amount = stock_value.amount - delta
    yield
    stock_value.repository_ledger_records.create!(
      reference: self,
      user: last_modified_by,
      amount: delta,
      balance: stock_value.amount,
      comment: comment
    )
    stock_value.save!
    save!
  end
end
