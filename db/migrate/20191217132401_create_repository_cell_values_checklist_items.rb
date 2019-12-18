# frozen_string_literal: true

class CreateRepositoryCellValuesChecklistItems < ActiveRecord::Migration[6.0]
  def change
    create_table :repository_cell_values_checklist_items do |t|
      t.references :repository_checklist_item, null: false, foreign_key: true, 
                   index: { name: :repository_cell_values_checklist_item_id }
      t.references :repository_checklist_value, null: false, foreign_key: true, 
                   index: { name: :repository_cell_values_checklist_value_id }
      t.timestamps
    end
  end
end
