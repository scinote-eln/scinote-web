class AddAttachmentImageToTinyMceAssets < ActiveRecord::Migration
  def change
    create_table :tiny_mce_assets do |t|
      t.attachment :image
      t.boolean :editing, default: false
      t.integer :estimated_size, default: 0, null: false
      t.references :team, index: true
      t.references :step, index: true
      t.references :result_text, index: true
      t.timestamps null: false
    end
  end
end
