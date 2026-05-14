# frozen_string_literal: true

class RemoveFileImageQualityColumnFromAssets < ActiveRecord::Migration[7.2]
  def change
    remove_column :assets, :file_image_quality, :integer
  end
end
