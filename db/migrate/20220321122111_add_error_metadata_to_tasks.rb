# frozen_string_literal: true

class AddErrorMetadataToTasks < ActiveRecord::Migration[6.1]
  def change
    add_column :my_modules, :last_transition_error, :jsonb
  end
end
