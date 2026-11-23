# frozen_string_literal: true

class AddUniqueItemNamesCaseSensitiveToRepositories < ActiveRecord::Migration[7.2]
  def change
    add_column :repositories, :unique_item_names_case_sensitive, :boolean, default: false, null: false
  end
end
