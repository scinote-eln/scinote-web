class CreateSteps < ActiveRecord::Migration[4.2]
  def change
    create_table :steps do |t|
      t.string :name
      t.string :description
      t.integer :position, null: false
      t.boolean :completed, null: false
      t.datetime :completed_on
      t.integer :user_id, null: false
      t.integer :my_module_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :steps, :users
    add_foreign_key :steps, :my_modules
    add_index :steps, :my_module_id
    add_index :steps, :user_id
    add_index :steps, :created_at
    add_index :steps, :position
  end
end
