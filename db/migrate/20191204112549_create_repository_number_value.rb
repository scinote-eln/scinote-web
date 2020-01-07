# frozen_string_literal: true

class CreateRepositoryNumberValue < ActiveRecord::Migration[6.0]
  def change
    create_table :repository_number_values do |t|
      t.decimal :data, index: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }
      t.references :created_by, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
