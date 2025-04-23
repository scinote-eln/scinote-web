# frozen_string_literal: true

class RemoveDataColumnFromAssetTextData < ActiveRecord::Migration[7.0]
  def change
    remove_column :asset_text_data, :data, :text
  end
end
