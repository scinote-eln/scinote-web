# frozen_string_literal: true

class AddDuplicatesFlagsToRepositories < ActiveRecord::Migration[7.2]
  def change
    add_column :repositories, :duplicated_items_count, :integer, default: 0, null: false
    add_column :repository_rows, :duplicated, :boolean, default: false, null: false
    add_index :repository_rows, :repository_id, where: 'duplicated', name: 'index_repository_rows_on_repository_id_duplicated'
  end
end
