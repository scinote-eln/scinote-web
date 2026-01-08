# frozen_string_literal: true

class CreateProtocolRepositoryRows < ActiveRecord::Migration[7.2]
  def change
    create_table :protocol_repository_rows do |t|
      t.references :protocol, null: false, foreign_key: true, index: false
      t.references :repository_row, null: true, foreign_key: true

      t.timestamps
    end

    add_index :protocol_repository_rows, %i(protocol_id repository_row_id), unique: true
  end
end
