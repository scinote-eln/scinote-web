class AddTeamIdToAssetAndTables < ActiveRecord::Migration[4.2]
  def change
    add_column :assets, :team_id, :integer
    add_index :assets, :team_id

    add_column :tables, :team_id, :integer
    add_index :tables, :team_id
  end
end
