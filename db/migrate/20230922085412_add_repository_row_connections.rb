# frozen_string_literal: true

class AddRepositoryRowConnections < ActiveRecord::Migration[7.0]
  def up
    create_table :repository_row_connections do |t|
      t.references :parent, index: true, foreign_key: { to_table: :repository_rows }
      t.references :child, index: true, foreign_key: { to_table: :repository_rows }
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :last_modified_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    change_table :repository_rows, bulk: true do |t|
      t.integer :parent_connections_count
      t.integer :child_connections_count
    end

    add_index :repository_row_connections,
              'LEAST(parent_id, child_id), GREATEST(parent_id, child_id)',
              name: 'index_repository_row_connections_on_connection_pair',
              unique: true
    add_check_constraint :repository_row_connections, 'parent_id != child_id',
                         name: 'constraint_repository_row_connections_on_self_connection'
  end

  def down
    remove_check_constraint :repository_row_connections,
                            name: 'constraint_repository_row_connections_on_self_connection'
    remove_index :repository_row_connections, 'index_repository_row_connections_on_connection_pair'
    remove_columns :repository_rows, :parent_connections_count, :child_connections_count
    drop_table :repository_row_connections
  end
end
