# frozen_string_literal: true

class CreateRepositoryChecklistValues < ActiveRecord::Migration[6.0]
  def change
    create_table :repository_checklist_values do |t|
      t.references :created_by, index: true, foreign_key: { to_table: :users }, null: true
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end
  end
end
