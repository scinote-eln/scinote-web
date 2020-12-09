# frozen_string_literal: true

class AddAssetsViewModeToStep < ActiveRecord::Migration[6.0]
  def change
    add_column :steps, :assets_view_mode, :integer, default: 0, null: false
  end
end
