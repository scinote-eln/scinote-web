class AddAssetsViewModeToResult < ActiveRecord::Migration[7.0]
  def change
    add_column :results, :assets_view_mode, :integer, default: 0
    change_column_null :result_texts, :text, true
  end
end
