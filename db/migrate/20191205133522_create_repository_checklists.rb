# frozen_string_literal: true

class CreateRepositoryChecklists < ActiveRecord::Migration[6.0]
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

    create_table :repository_checklist_items_values do |t|
      t.belongs_to :repository_checklist_value, index: { name: 'index_on_repository_checklist_value_id' }
      t.belongs_to :repository_checklist_item, index: { name: 'index_on_repository_checklist_item_id' }
      t.timestamps
    end
  end
end
