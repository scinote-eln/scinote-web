class CreateAssetTextData < ActiveRecord::Migration[4.2]
  def change
    create_table :asset_text_data do |t|
      t.text :data, null: false
      t.integer :asset_id, null: false
      t.timestamps null: false
    end
    add_foreign_key :asset_text_data, :assets
    add_index :asset_text_data, :asset_id, unique: true
  end
end
