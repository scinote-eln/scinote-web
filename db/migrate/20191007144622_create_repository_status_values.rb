# frozen_string_literal: true

class CreateRepositoryStatusValues < ActiveRecord::Migration[6.0]
  def change
    create_table :repository_status_values do |t|
      t.references :created_by, index: true, foreign_key: { to_table: :users }, null: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }, null: true
      t.references :repository_status_item, null: false, foreign_key: true,
                   index: { name: 'index_on_rep_status_type_id' }

      t.timestamps
    end
  end
end
