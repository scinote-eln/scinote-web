# frozen_string_literal: true

class AddResultTemplates < ActiveRecord::Migration[7.2]
  def up
    change_table :results, bulk: true do |t|
      t.string :type
      t.references :protocol, null: true
    end

    change_column_null :results, :my_module_id, true

    execute "UPDATE \"results\" SET \"type\" = 'Result'"
  end

  def down
    change_table :results, bulk: true do |t|
      t.remove :type
      t.remove_references :protocol
    end

    change_column_null :results, :my_module_id, false
  end
end
