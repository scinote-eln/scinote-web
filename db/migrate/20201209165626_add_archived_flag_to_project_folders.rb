# frozen_string_literal: true

class AddArchivedFlagToProjectFolders < ActiveRecord::Migration[6.0]
  def change
    change_table :project_folders, bulk: true do |t|
      t.boolean :archived, default: false
      t.references :archived_by, foreign_key: { to_table: :users }, index: false
      t.datetime :archived_on
      t.references :restored_by, foreign_key: { to_table: :users }, index: false
      t.datetime :restored_on
    end
  end
end
