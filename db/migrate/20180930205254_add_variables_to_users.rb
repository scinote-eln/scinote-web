# frozen_string_literal: true

class AddVariablesToUsers < ActiveRecord::Migration[5.1]
  VARIABLES = {
    export_vars: {
      num_of_export_all_last_24_hours: 0
    }
  }.freeze

  def up
    add_column :users, :variables, :jsonb, default: {}, null: false
    User.reset_column_information
    User.update_all(variables: VARIABLES)
  end

  def down
    remove_column :users, :variables, :jsonb
  end
end
