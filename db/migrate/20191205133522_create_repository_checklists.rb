# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class CreateRepositoryChecklists < ActiveRecord::Migration[6.0]
  include DatabaseHelper

  def up
    create_table :repository_checklist_values do |t|
      t.references :created_by, index: true, foreign_key: { to_table: :users }, null: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    create_table :repository_checklist_items do |t|
      t.string :data, null: false
      t.references :repository, null: false, foreign_key: true
      t.references :repository_column, null: false, foreign_key: true
      t.references :created_by, index: true, foreign_key: { to_table: :users }, null: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_gin_index_without_tags :repository_checklist_items, :data

    create_table :repository_checklist_items_values do |t|
      t.belongs_to :repository_checklist_value, index: { name: 'index_on_repository_checklist_value_id' }
      t.belongs_to :repository_checklist_item, index: { name: 'index_on_repository_checklist_item_id' }
      t.timestamps
    end
  end

  def down
    drop_table :repository_checklist_items_values
    drop_table :repository_checklist_items
    drop_table :repository_checklist_values
  end
end
