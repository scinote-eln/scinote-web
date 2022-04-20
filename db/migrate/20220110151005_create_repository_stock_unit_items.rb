# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class CreateRepositoryStockUnitItems < ActiveRecord::Migration[6.0]
  include DatabaseHelper

  def up
    create_table :repository_stock_unit_items do |t|
      t.string :data, null: false
      t.references :repository_column, null: false, foreign_key: true
      t.references :created_by, index: true, foreign_key: { to_table: :users }, null: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_gin_index_without_tags :repository_stock_unit_items, :data
  end

  def down
    drop_table :repository_stock_unit_items
  end
end
