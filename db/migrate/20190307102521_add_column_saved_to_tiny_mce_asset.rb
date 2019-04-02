# frozen_string_literal: true
class AddColumnSavedToTinyMceAsset < ActiveRecord::Migration[5.1]
  def change
    add_column :tiny_mce_assets, :saved, :boolean, default: true
  end
end
