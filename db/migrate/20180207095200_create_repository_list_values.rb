require File.expand_path('app/helpers/database_helper')

class CreateRepositoryListValues < ActiveRecord::Migration[5.1]
  include DatabaseHelper

  def up
    create_table :repository_list_items do |t|
      t.references :repository, index: true, foreign_key: true
      t.references :repository_column, index: true, foreign_key: true
      t.text :data, null: false
      t.references :created_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.references :last_modified_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.timestamps
    end

    add_gin_index_without_tags :repository_list_items, :data

    create_table :repository_list_values do |t|
      t.references :repository_list_item, index: true
      t.references :created_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.references :last_modified_by,
                   index: true,
                   foreign_key: { to_table: :users }
      t.timestamps
    end
  end

  def down
    drop_table :repository_list_items
    drop_table :repository_list_values
  end
end
