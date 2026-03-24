# frozen_string_literal: true

class AddArchiveToAssets < ActiveRecord::Migration[7.2]
  def change
    add_column :assets, :archived, :boolean, default: false, null: false
    add_column :assets, :archived_on, :datetime
    add_column :assets, :restored_on, :datetime
    add_reference :assets, :archived_by, foreign_key: { to_table: :users }, null: true
    add_reference :assets, :restored_by, foreign_key: { to_table: :users }, null: true

    add_index :assets, :archived
  end
end
