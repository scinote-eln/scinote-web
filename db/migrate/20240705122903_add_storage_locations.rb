# frozen_string_literal: true

class AddStorageLocations < ActiveRecord::Migration[7.0]
  include DatabaseHelper

  def up
    create_table :storage_locations do |t|
      t.string :name
      t.string :description
      t.references :parent, index: true, foreign_key: { to_table: :storage_locations }
      t.references :team, index: true, foreign_key: { to_table: :teams }
      t.references :created_by, foreign_key: { to_table: :users }
      t.boolean :container, default: false, null: false, index: true
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at, index: true

      t.timestamps
    end

    create_table :storage_location_repository_rows do |t|
      t.references :repository_row, index: true, foreign_key: { to_table: :repository_rows }
      t.references :storage_location, index: true, foreign_key: { to_table: :storage_locations }
      t.references :created_by, foreign_key: { to_table: :users }
      t.jsonb :metadata, null: false, default: {}
      t.datetime :discarded_at, index: true

      t.timestamps
    end

    add_gin_index_without_tags :storage_locations, :name
    add_gin_index_without_tags :storage_locations, :description
  end

  def down
    drop_table :storage_location_repository_rows
    drop_table :storage_locations
  end
end
