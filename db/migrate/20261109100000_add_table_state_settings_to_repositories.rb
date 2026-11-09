# frozen_string_literal: true

class AddTableStateSettingsToRepositories < ActiveRecord::Migration[7.2]
  def change
    change_table :repositories, bulk: true do |t|
      t.boolean :enforce_table_state, default: false, null: false
      t.jsonb :default_table_state
    end

    add_column :repository_columns, :mandatory, :boolean, default: false, null: false
  end
end
