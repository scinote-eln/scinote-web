# frozen_string_literal: true

class CreateBmtFilters < ActiveRecord::Migration[6.1]
  def change
    create_table :bmt_filters do |t|
      t.string :name, null: false
      t.json :filters, null: false
      t.references :created_by, index: true, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
