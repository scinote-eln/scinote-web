# frozen_string_literal: true

class CreateRepositoryTemplate < ActiveRecord::Migration[7.0]
  def change
    create_table :repository_templates do |t|
      t.string :name
      t.jsonb :column_definitions
      t.references :team, index: true, foreign_key: { to_table: :teams }
      t.boolean :predefined, null: false, default: false

      t.timestamps
    end

    add_reference :repositories, :repository_template, null: true, foreign_key: true
  end
end
