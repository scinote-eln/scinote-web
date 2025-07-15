class AddCurrentOrganizationToUser < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :current_team_id, :integer
    add_foreign_key :users, :teams, column: :current_team_id
  end

  def down
    remove_column :users, :current_team_id
  end
end
