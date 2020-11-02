# frozen_string_literal: true

class CreateProjectFolders < ActiveRecord::Migration[6.0]
  include DatabaseHelper

  def up
    create_table :project_folders do |t|
      t.string :name, null: false
      t.references :team, index: true, null: false, foreign_key: true
      t.references :parent_folder, index: true, foreign_key: { to_table: :project_folders }, null: true
      t.timestamps
    end

    add_reference :projects, :project_folder, index: true, foreign_key: true

    add_gin_index_without_tags :project_folders, :name
  end

  def down
    remove_index :project_folders, name: :index_project_folders_on_name

    remove_reference :projects, :project_folder, index: true, foreign_key: true

    drop_table :project_folders
  end
end
