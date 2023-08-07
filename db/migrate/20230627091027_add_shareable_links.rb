# frozen_string_literal: true

class AddShareableLinks < ActiveRecord::Migration[6.1]
  def change
    create_table :shareable_links do |t|
      t.string :uuid, index: true
      t.string :description
      t.references :shareable, polymorphic: true, index: true
      t.references :team, index: true, foreign_key: { to_table: :teams }
      t.references :created_by, index: true, foreign_key: { to_table: :users }
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_column :teams, :shareable_links_enabled, :boolean, default: false, null: false
  end
end
