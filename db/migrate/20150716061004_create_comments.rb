class CreateComments < ActiveRecord::Migration[4.2]
  def change
    create_table :comments do |t|
      t.string :message, null: false
      t.integer :user_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :comments, :users
    add_index :comments, :user_id
    add_index :comments, :created_at
  end
end
