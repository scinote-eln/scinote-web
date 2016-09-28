class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :title
      t.string :message
      t.integer :type_of, null: false

      t.timestamps null: false
    end
    add_index :notifications, :created_at
  end
end
