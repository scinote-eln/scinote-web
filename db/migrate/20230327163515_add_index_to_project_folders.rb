# frozen_string_literal: true

class AddIndexToProjectFolders < ActiveRecord::Migration[6.1]
  def change
    add_index :project_folders, :archived
  end
end
