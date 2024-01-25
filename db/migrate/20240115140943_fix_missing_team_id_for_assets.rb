# frozen_string_literal: true

class FixMissingTeamIdForAssets < ActiveRecord::Migration[7.0]
  def up
    # step assets
    execute(
      'UPDATE assets ' \
      'SET team_id = protocols.team_id ' \
      'FROM protocols ' \
      'INNER JOIN steps ON steps.protocol_id = protocols.id ' \
      'INNER JOIN step_assets ON step_assets.step_id = steps.id ' \
      'WHERE step_assets.asset_id = assets.id ' \
      'AND (protocols.team_id != assets.team_id OR assets.team_id IS NULL)'
    )

    # result assets
    execute(
      'UPDATE assets ' \
      'SET team_id = protocols.team_id ' \
      'FROM protocols ' \
      'INNER JOIN my_modules ON my_modules.id = protocols.my_module_id ' \
      'INNER JOIN results ON results.my_module_id = my_modules.id ' \
      'INNER JOIN result_assets ON result_assets.result_id = results.id ' \
      'WHERE result_assets.asset_id = assets.id ' \
      'AND (protocols.team_id != assets.team_id OR assets.team_id IS NULL)'
    )

    # repository assets
    execute(
      'UPDATE assets ' \
      'SET team_id = repositories.team_id ' \
      'FROM repositories ' \
      'INNER JOIN repository_columns ON repository_columns.repository_id = repositories.id ' \
      'INNER JOIN repository_cells ON repository_cells.repository_column_id = repository_columns.id ' \
      'INNER JOIN repository_asset_values ON repository_asset_values.id = repository_cells.value_id ' \
      'AND repository_cells.value_type = \'RepositoryAssetValue\' ' \
      'WHERE repository_asset_values.asset_id = assets.id ' \
      'AND assets.team_id IS NULL'
    )
  end
end
