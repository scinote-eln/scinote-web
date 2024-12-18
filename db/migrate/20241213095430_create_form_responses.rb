# frozen_string_literal: true

class CreateFormResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :form_responses do |t|
      t.references :form, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :submitted_by, null: true, foreign_key: { to_table: :users }
      t.integer :status, default: 0
      t.datetime :submitted_at
      t.datetime :discarded_at

      t.timestamps
    end
  end
end
