class CreateUserMyModules < ActiveRecord::Migration[4.2]
  def change
    create_table :user_my_modules do |t|
      t.integer :user_id, null: false
      t.integer :my_module_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :user_my_modules, :users
    add_foreign_key :user_my_modules, :my_modules
    add_index :user_my_modules, :user_id
    add_index :user_my_modules, :my_module_id
  end
end
