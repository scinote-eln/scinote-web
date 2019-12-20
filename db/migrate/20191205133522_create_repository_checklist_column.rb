# frozen_string_literal: true

class CreateRepositoryChecklistColumn < ActiveRecord::Migration[6.0]
  def change
    create_table :repository_checklist_values do |t|
      t.references :created_by, index: true, foreign_key: { to_table: :users }, null: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    create_table :repository_checklist_items do |t|
      t.string :data, null: false, index: true
      t.references :repository, null: false, foreign_key: true
      t.references :repository_column, null: false, foreign_key: true
      t.references :created_by, index: true, foreign_key: { to_table: :users }, null: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    create_table :repository_cell_values_checklist_items do |t|
      t.references :repository_checklist_item, null: false, foreign_key: true,
                   index: { name: :repository_cell_values_checklist_item_id }
      t.references :repository_checklist_value, null: false, foreign_key: true,
                   index: { name: :repository_cell_values_checklist_value_id }
      t.timestamps
    end
  end
end
