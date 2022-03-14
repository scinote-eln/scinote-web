# frozen_string_literal: true

class AddRepositoryFilters < ActiveRecord::Migration[6.1]
  def change
    create_table :repository_table_filters do |t|
      t.string :name, null: false
      t.jsonb :default_columns, null: false, default: {}
      t.references :repository, index: true
      t.references :created_by, index: true, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :repository_table_filter_elements do |t|
      t.references :repository_table_filter, index: { name: 'index_on_repository_table_filter_id' }
      t.references :repository_column, index: true
      t.integer :operator
      t.jsonb :parameters, null: false, default: {}
      t.timestamps
    end
  end
end
