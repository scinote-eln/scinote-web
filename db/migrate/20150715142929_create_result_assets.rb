class CreateResultAssets < ActiveRecord::Migration[4.2]
  def change
    create_table :result_assets do |t|
      t.integer :result_id, null: false
      t.integer :asset_id, null: false
    end
    add_foreign_key :result_assets, :assets
    add_index :result_assets, [:result_id, :asset_id]
  end
end
