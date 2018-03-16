class CreateRepositoryAssetValues < ActiveRecord::Migration[5.1]
  def change
    create_table :repository_asset_values do |t|
      t.references :asset, index: true
      t.references :created_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.references :last_modified_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
