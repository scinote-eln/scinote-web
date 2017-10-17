class AddProcessingToAssets < ActiveRecord::Migration
  def change
    add_column :assets, :file_processing, :boolean
  end
end
