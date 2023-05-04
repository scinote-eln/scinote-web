# frozen_string_literal: true

class AssetChangeEstimatedSizeToBigint < ActiveRecord::Migration[6.1]
  def up
    change_column :assets, :estimated_size, :bigint
    change_column :tiny_mce_assets, :estimated_size, :bigint
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
