# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class CreateExternalIdColumnForRepositories < ActiveRecord::Migration[7.0]
  include DatabaseHelper

  def up
    add_column :repositories, :external_id, :string, null: true
    add_index :repositories,
              %i(team_id external_id),
              unique: true,
              name: 'unique_index_repositories_on_external_id'
    remove_index :repository_rows, name: 'index_repository_checklist_items_on_external_id'
    remove_index :repository_rows, name: 'index_repository_list_items_on_external_id'
    remove_index :repository_rows, name: 'index_repository_rows_on_external_id'
  end

  def down
    remove_index :repositories, name: 'unique_index_repositories_on_external_id'
    remove_column :repositories, :external_id, :string, null: true

    add_gin_index_without_tags(:repository_list_items, :external_id)
    add_gin_index_without_tags(:repository_checklist_items, :external_id)
    add_gin_index_without_tags(:repository_rows, :external_id)
  end
end
