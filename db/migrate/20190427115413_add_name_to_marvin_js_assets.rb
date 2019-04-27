# frozen_string_literal: true
class AddNameToMarvinJsAssets < ActiveRecord::Migration[5.1]
  def change
    add_column :marvin_js_assets, :name, :string
  end
end
