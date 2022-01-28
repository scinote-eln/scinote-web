# frozen_string_literal: true

class AddRepositoryStockManagement < ActiveRecord::Migration[6.1]
  def change
    create_table :repository_stock_values do |t|
      t.decimal :amount, index: true
      t.references :repository_stock_unit_item, index: true, foreign_key: true
      t.string :type
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }
      t.references :created_by, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    create_table :repository_ledger_records do |t|
      t.references :repository_stock_value, null: false, index: true, foreign_key: true
      t.references :reference, polymorphic: true, null: false
      t.decimal :amount
      t.decimal :balance
      t.references :user, null: true
      t.text :comment

      t.timestamps
    end

    add_column :my_module_repository_rows, :stock_consumption, :decimal
    add_reference :my_module_repository_rows,
                  :repository_stock_unit_item,
                  index: { name: 'index_on_repository_stock_unit_item_id' },
                  foreign_key: true
  end
end
