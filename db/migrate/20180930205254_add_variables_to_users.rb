# frozen_string_literal: true

class AddVariablesToUsers < ActiveRecord::Migration[5.1]
  def up
    add_column :users, :variables, :jsonb, default: {}, null: false

    User.find_each do |user|
      variables = {
        export_vars: {
          num_of_export_all_last_24_hours: 0
        }
      }

      user.update(variables: variables)
    end
  end

  def down
    remove_column :users, :variables, :jsonb
  end
end
