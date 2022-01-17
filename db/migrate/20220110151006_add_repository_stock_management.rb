# frozen_string_literal: true

class AddRepositoryStockManagement < ActiveRecord::Migration[6.1]
  def change
    create_table :repository_ledger_records do |t|
      t.references :repository_row, null: false, index: true, foreign_key: true
      t.references :reference, polymorphic: true, null: false
      t.decimal :amount
      t.decimal :balance
      t.references :user, null: true

      t.timestamps
    end

    create_table :repository_stock_values do |t|
      t.decimal :amount, index: true
      t.string :units
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }
      t.references :created_by, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_column :my_module_repository_rows, :stock_consumption, :decimal
  end
end
