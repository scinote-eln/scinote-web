class CreateStepTables < ActiveRecord::Migration[4.2]
  def change
    create_table :step_tables do |t|
      t.integer :step_id, null: false
      t.integer :table_id, null: false
    end
    add_foreign_key :step_tables, :steps
    add_foreign_key :step_tables, :tables
    add_index :step_tables, [:step_id, :table_id], unique: true
  end
end
