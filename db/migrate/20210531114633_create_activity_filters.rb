# frozen_string_literal: true

class CreateActivityFilters < ActiveRecord::Migration[6.0]
  def change
    create_table :activity_filters do |t|
      t.string :name, null: false
      t.jsonb :filter, null: false

      t.timestamps
    end
  end
end
