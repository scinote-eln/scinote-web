class CreateStepAssets < ActiveRecord::Migration[4.2]
  def change
    create_table :step_assets do |t|
      t.integer :step_id, null: false
      t.integer :asset_id, null: false
    end
    add_foreign_key :step_assets, :steps
    add_foreign_key :step_assets, :assets
    add_index :step_assets, [:step_id, :asset_id]
  end
end
