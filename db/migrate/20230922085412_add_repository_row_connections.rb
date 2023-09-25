# frozen_string_literal: true

class AddRepositoryRowConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :repository_row_connections do |t|
      t.references :parent, index: true, foreign_key: { to_table: :repository_rows }
      t.references :child, index: true, foreign_key: { to_table: :repository_rows }
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :last_modified_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :repository_row_connections, %i(parent_id child_id), unique: true

    change_table :repository_rows, bulk: true do |t|
      t.integer :parent_connections_count
      t.integer :child_connections_count
    end
  end
end
