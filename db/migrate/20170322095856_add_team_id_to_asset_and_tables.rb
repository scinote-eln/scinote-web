class AddTeamIdToAssetAndTables < ActiveRecord::Migration[4.2]
  def change
    add_column :assets, :team_id, :integer
    add_index :assets, :team_id

    add_column :tables, :team_id, :integer
    add_index :tables, :team_id

    Asset.find_each do |asset|
      if asset.result
        asset.update_columns(
          team_id: asset.result.my_module.experiment.project.team_id
        )
      elsif asset.step
        asset.update_columns(team_id: asset.step.protocol.team_id)
      end
    end

    Table.find_each do |table|
      if table.result
        table.update_columns(
          team_id: table.result.my_module.experiment.project.team_id
        )
      elsif table.step
        table.update_columns(team_id: table.step.protocol.team_id)
      end
    end
  end
end
