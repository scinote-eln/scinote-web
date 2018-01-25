class CreateChecklistItems < ActiveRecord::Migration[4.2]
  def change
    create_table :checklist_items do |t|
      t.string :text, null: false
      t.boolean :checked, null: false, default: false
      t.integer :checklist_id, null: false

      t.timestamps null: false
    end
    add_index :checklist_items, :checklist_id
  end
end
