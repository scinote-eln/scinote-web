class CreateStepTinyMceAssets < ActiveRecord::Migration
  def change
    create_table :step_tiny_mce_assets do |t|
      t.references :step, index: true, foreign_key: true
      t.references :asset, index: true, foreign_key: true
      t.boolean :edited, default: false

      t.timestamps null: false
    end
  end
end
