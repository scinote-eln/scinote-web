# frozen_string_literal: true

class AddColumnQualityToAsset < ActiveRecord::Migration[5.1]
  def change
    add_column :assets, :quality, :integer
  end
end
