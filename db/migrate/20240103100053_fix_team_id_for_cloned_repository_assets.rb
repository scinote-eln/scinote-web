# frozen_string_literal: true

class FixTeamIdForClonedRepositoryAssets < ActiveRecord::Migration[7.0]
  def up
    execute(
      'UPDATE "assets" ' \
      'SET "team_id" = "repositories"."team_id" ' \
      'FROM "repositories" ' \
      'INNER JOIN "repository_columns" ON "repository_columns"."repository_id" = "repositories"."id" ' \
      'INNER JOIN "repository_cells" ON "repository_cells"."repository_column_id" = "repository_columns"."id" ' \
      'INNER JOIN "repository_asset_values" ON "repository_asset_values"."id" = "repository_cells"."value_id" ' \
      'AND "repository_cells"."value_type" = \'RepositoryAssetValue\' ' \
      'WHERE "repository_asset_values"."asset_id" = "assets"."id" AND "assets"."team_id" != "repositories"."team_id"'
    )
  end
end
