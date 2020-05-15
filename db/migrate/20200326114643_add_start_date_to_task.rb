# frozen_string_literal: true

class AddStartDateToTask < ActiveRecord::Migration[6.0]
  def change
    add_column :my_modules, :started_on, :datetime, null: true
  end
end
