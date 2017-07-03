class AddProcessingToAssets < ActiveRecord::Migration[4.2]
  def change
    add_column :assets, :file_processing, :boolean
  end
end
