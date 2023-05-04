# frozen_string_literal: true

class AddMissingIndexesOnArchived < ActiveRecord::Migration[6.1]
  def change
    add_index :repositories, :archived
    add_index :repository_rows, :archived
    add_index :experiments, :archived
    add_index :my_modules, :archived
    add_index :projects, :archived
    add_index :results, :archived
    add_index :project_folders, :archived
  end
end
