class AddFileTitleToAsset < ActiveRecord::Migration[8.1]
  def change
    add_column :assets, :file_title, :string
  end
end
