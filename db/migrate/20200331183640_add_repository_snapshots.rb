# frozen_string_literal: true

class AddRepositorySnapshots < ActiveRecord::Migration[6.0]
  def change
    change_table :repositories, bulk: true do |t|
      t.boolean :snapshot, default: false
      t.bigint :parent_id, null: true
      t.bigint :my_module_id, null: true, index: true
    end

    add_column :repository_rows, :parent_id, :bigint, null: true
  end
end
