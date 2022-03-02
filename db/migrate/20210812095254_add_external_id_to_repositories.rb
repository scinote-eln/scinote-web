# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class AddExternalIdToRepositories < ActiveRecord::Migration[6.1]
  include DatabaseHelper

  def up
    add_column :repository_rows, :external_id, :string, null: true
    add_index :repository_rows, :external_id, unique: true, name: 'unique_index_repository_rows_on_external_id'
    add_gin_index_without_tags(:repository_rows, :external_id)
  end

  def down
    remove_index :repository_rows, name: 'index_repository_rows_on_external_id'
    remove_index :repository_rows, :external_id, unique: true, name: 'unique_index_repository_rows_on_external_id'
    remove_column :repository_rows, :external_id, :string, null: true
  end
end
