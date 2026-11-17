# frozen_string_literal: true

class AddEnforceUniqueItemNamesToRepositories < ActiveRecord::Migration[7.2]
  def change
    add_column :repositories, :enforce_unique_item_names, :boolean, default: false, null: false
  end
end
