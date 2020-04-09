# frozen_string_literal: true

class AddRepositorySnapshots < ActiveRecord::Migration[6.0]
  def up
    add_column :repositories, :parent_id, :bigint, null: true
    add_reference :repositories, :my_module
    add_column :repositories, :type, :string

    execute "UPDATE \"repositories\" SET \"type\" = 'Repository'"
    execute "UPDATE \"activities\" SET \"subject_type\" = 'RepositoryBase' WHERE \"subject_type\" = 'Repository'"

    add_column :repository_columns, :parent_id, :bigint, null: true
    add_column :repository_rows, :parent_id, :bigint, null: true

    remove_reference :repository_list_items, :repository, index: true, foreign_key: true
    remove_reference :repository_status_items, :repository, foreign_key: true
    remove_reference :repository_checklist_items, :repository, foreign_key: true
  end

  def down
    add_reference :repository_list_items, :repository, index: true, foreign_key: true
    add_reference :repository_status_items, :repository, index: true, foreign_key: true
    add_reference :repository_checklist_items, :repository, index: true, foreign_key: true

    remove_column :repository_columns, :parent_id
    remove_column :repository_rows, :parent_id

    execute "UPDATE \"activities\" SET \"subject_type\" = 'Repository' WHERE \"subject_type\" = 'RepositoryBase'"

    remove_column :repositories, :parent_id, :bigint, null: true
    remove_reference :repositories, :my_module
    remove_column :repositories, :type, :string
  end
end
