# frozen_string_literal: true

class CreateStepOrderableElements < ActiveRecord::Migration[6.1]
  def change
    create_table :step_orderable_elements do |t|
      t.references :step, null: false, index: true, foreign_key: true
      t.integer :position
      t.references :orderable, polymorphic: true

      t.timestamps
    end
  end
end
