class AddTeamIdToAssetAndTables < ActiveRecord::Migration[4.2]
  class TempAsset < ApplicationRecord
    self.table_name = 'assets'
    has_one :result_asset, foreign_key: :asset_id
    has_one :result, through: :result_asset
    has_one :step_asset, foreign_key: :asset_id
    has_one :step, through: :step_asset
  end

  def change
    add_column :assets, :team_id, :integer
    add_index :assets, :team_id

    add_column :tables, :team_id, :integer
    add_index :tables, :team_id

    TempAsset.find_each do |asset|
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
