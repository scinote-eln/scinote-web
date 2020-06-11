# frozen_string_literal: true

class AddArchiveToRepository < ActiveRecord::Migration[6.0]
  def change
    change_table :repositories, bulk: true do |t|
      t.boolean :archived, default: false, null: false
      t.datetime :archived_on
      t.datetime :restored_on
      t.references :archived_by, index: true, foreign_key: { to_table: :users }
      t.references :restored_by, index: true, foreign_key: { to_table: :users }
    end
  end
end
