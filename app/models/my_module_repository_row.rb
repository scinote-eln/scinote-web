class MyModuleRepositoryRow < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  attribute :last_modified_by_id, :integer
  attribute :comment, :text

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
  has_many :repository_ledger_records, as: :reference

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
        last_modified_by_id: user.id,
        comment: comment
      )
      save!
    end
  end

  def formated_stock_consumption
    if stock_consumption
      number_with_precision(
        stock_consumption,
        precision: (repository_row.repository.repository_stock_column.metadata['decimals'].to_i || 0),
        strip_insignificant_zeros: true
      )
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
      user_id: last_modified_by_id || assigned_by_id,
      amount: delta,
      balance: stock_value.amount,
      comment: comment,
      unit: stock_value.repository_stock_unit_item&.data,
      my_module_references: {
        my_module_id: my_module.id,
        experiment_id: my_module.experiment.id,
        project_id: my_module.experiment.project.id,
        team_id: my_module.experiment.project.team.id
      }
    )
    stock_value.save!
    save!
  end
end
