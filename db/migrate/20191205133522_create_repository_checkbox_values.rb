# frozen_string_literal: true

class CreateRepositoryCheckboxValues < ActiveRecord::Migration[6.0]
  def change
    create_table :repository_checkbox_values do |t|
      t.references :created_by, index: true, foreign_key: { to_table: :users }, null: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }, null: true
      t.jsonb :repository_checkboxes_items,

      t.timestamps
    end
  end
end
