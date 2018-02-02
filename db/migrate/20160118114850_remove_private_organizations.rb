class RemovePrivateOrganizations < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key :teams, column: :private_user_id
    remove_index :teams, :private_user_id
    remove_column :teams, :private_user_id
  end

  def down
    add_column :teams, :private_user_id, :integer
    add_index :teams, :private_user_id
    add_foreign_key :teams, :users, column: :private_user_id
  end
end
