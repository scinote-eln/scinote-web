# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class AddExternalIdToRepositoryColumnItems < ActiveRecord::Migration[6.1]
  include DatabaseHelper

  def up
    add_column :repository_list_items, :external_id, :string, null: true
    add_column :repository_checklist_items, :external_id, :string, null: true
    add_index :repository_list_items,
              %i(repository_column_id external_id),
              unique: true,
              name: 'unique_index_repository_list_items_on_external_id'
    add_index :repository_checklist_items,
              %i(repository_column_id external_id),
              unique: true,
              name: 'unique_index_repository_checklist_items_on_external_id'
    add_gin_index_without_tags(:repository_list_items, :external_id)
    add_gin_index_without_tags(:repository_checklist_items, :external_id)

    remove_index :repository_rows, :external_id, unique: true, name: 'unique_index_repository_rows_on_external_id'
    add_index :repository_rows,
              %i(repository_id external_id),
              unique: true,
              name: 'unique_index_repository_rows_on_external_id'
  end

  def down
    remove_index :repository_rows, name: 'unique_index_repository_rows_on_external_id'
    add_index :repository_rows, :external_id, unique: true, name: 'unique_index_repository_rows_on_external_id'

    remove_index :repository_rows, name: 'index_repository_checklist_items_on_external_id'
    remove_index :repository_rows, name: 'index_repository_list_items_on_external_id'
    remove_index :repository_checklist_items, name: 'unique_index_repository_checklist_items_on_external_id'
    remove_index :repository_list_items, name: 'unique_index_repository_list_items_on_external_id'
    remove_column :repository_checklist_items, :external_id, :string, null: true
    remove_column :repository_list_items, :external_id, :string, null: true
  end
end
