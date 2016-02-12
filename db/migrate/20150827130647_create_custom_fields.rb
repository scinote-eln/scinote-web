class CreateCustomFields < ActiveRecord::Migration
  def change
    create_table :custom_fields do |t|
      t.string :name, null: false

      t.integer :user_id, null: false
      t.integer :organization_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :custom_fields, :users
    add_foreign_key :custom_fields, :organizations

    add_index :custom_fields, :user_id
    add_index :custom_fields, :organization_id
  end
end
