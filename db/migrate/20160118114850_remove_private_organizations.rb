class RemovePrivateOrganizations < ActiveRecord::Migration
  def up
    remove_foreign_key :organizations, column: :private_user_id
    remove_index :organizations, :private_user_id
    remove_column :organizations, :private_user_id
  end

  def down
    add_column :organizations, :private_user_id, :integer
    add_index :organizations, :private_user_id
    add_foreign_key :organizations, :users, column: :private_user_id
  end
end
