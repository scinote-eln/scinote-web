class CreateUserOrganizations < ActiveRecord::Migration
  def change
    create_table :user_organizations do |t|
      t.column :role, :integer, null: false, default: 1
      t.integer :user_id, null: false
      t.integer :organization_id, null: false

      t.timestamps null: false
    end
    add_foreign_key :user_organizations, :users
    add_foreign_key :user_organizations, :organizations
  end
end
