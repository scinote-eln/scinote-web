class AddAttachmentImageToTinyMceAssets < ActiveRecord::Migration[4.2]
  def change
    create_table :tiny_mce_assets do |t|
      t.integer :estimated_size, default: 0, null: false
      t.references :step, index: true
      t.references :team, index: true
      t.references :result_text, index: true
      t.timestamps null: false
    end
  end
end
