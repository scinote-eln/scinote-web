class CreateWidgets < ActiveRecord::Migration
  def change
    create_table :widgets do |t|
      t.integer :widget_type, null: false
      t.integer :position, null: false
      t.jsonb :properties, null: false, default: {}
      t.integer :added_by_id, null: false
      t.integer :last_modified_by_id
      t.integer :my_module_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :widgets, :users, column: :added_by_id
    add_foreign_key :widgets, :users, column: :last_modified_by_id
    add_foreign_key :widgets, :my_modules
    add_index :widgets, :position
    add_index :widgets, :added_by_id
    add_index :widgets, :last_modified_by_id
    add_index :widgets, :my_module_id
    add_index :widgets, [:my_module_id, :position], unique: true
    add_index :widgets, :created_at
  end
end
