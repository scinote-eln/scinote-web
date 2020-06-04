# frozen_string_literal: true

class AddArchiveToRepositoryRow < ActiveRecord::Migration[6.0]
  def change
    change_table :repository_rows, bulk: true do |t|
      t.boolean :archived, default: false, null: false
      t.datetime :archived_on
      t.references :archived_by, index: true, foreign_key: { to_table: :users }
    end
  end
end
