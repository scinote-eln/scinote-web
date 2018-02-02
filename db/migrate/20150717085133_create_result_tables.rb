class CreateResultTables < ActiveRecord::Migration[4.2]
  def change
    create_table :result_tables do |t|
      t.integer :result_id, null: false
      t.integer :table_id, null: false
    end
    add_foreign_key :result_tables, :results
    add_foreign_key :result_tables, :tables
    add_index :result_tables, [:result_id, :table_id]
  end
end
