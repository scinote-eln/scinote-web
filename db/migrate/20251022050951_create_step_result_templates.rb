# frozen_string_literal: true

class CreateStepResultTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :step_result_templates do |t|
      t.references :step, null: false, foreign_key: true
      t.references :result_template, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
