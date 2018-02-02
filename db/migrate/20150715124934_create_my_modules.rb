class CreateMyModules < ActiveRecord::Migration[4.2]
  def change
    create_table :my_modules do |t|
      t.string :name, null: false
      t.datetime :due_date
      t.string :description

      # Positions
      t.integer :x, null: false, default: 0
      t.integer :y, null: false, default: 0

      # Foreign keys
      t.integer :project_id, null: false
      t.integer :my_module_group_id

      t.timestamps null: false
    end
    add_foreign_key :my_modules, :projects
    add_index :my_modules, :project_id
    add_index :my_modules, :my_module_group_id
  end
end
