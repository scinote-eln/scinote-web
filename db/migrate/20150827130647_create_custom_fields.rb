class CreateCustomFields < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_fields do |t|
      t.string :name, null: false

      t.integer :user_id, null: false
      t.integer :team_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :custom_fields, :users
    add_foreign_key :custom_fields, :teams

    add_index :custom_fields, :user_id
    add_index :custom_fields, :team_id
  end
end
