class CreateResults < ActiveRecord::Migration[4.2]
  def change
    create_table :results do |t|
      t.string :name
      t.integer :my_module_id, null: false
      t.integer :user_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :results, :users
    add_foreign_key :results, :my_modules
    add_index :results, :my_module_id
    add_index :results, :user_id
    add_index :results, :created_at
  end
end
