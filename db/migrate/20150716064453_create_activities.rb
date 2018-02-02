class CreateActivities < ActiveRecord::Migration[4.2]
  def change
    create_table :activities do |t|
      t.integer :my_module_id, null: false
      t.integer :user_id
      t.integer :type_of, null: false
      t.string :message, null: false

      t.timestamps null: false
    end
    add_foreign_key :activities, :my_modules
    add_foreign_key :activities, :users
    add_index :activities, :my_module_id
    add_index :activities, :user_id
    add_index :activities, :type_of
    add_index :activities, :created_at
  end
end
