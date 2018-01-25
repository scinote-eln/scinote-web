class CreateNotifications < ActiveRecord::Migration[4.2]
  def change
    create_table :notifications do |t|
      t.string :title
      t.string :message
      t.integer :type_of, null: false
      t.integer :generator_user_id

      t.timestamps null: false
    end
    add_index :notifications, :created_at
    add_foreign_key :notifications, :users, column: :generator_user_id
  end
end
