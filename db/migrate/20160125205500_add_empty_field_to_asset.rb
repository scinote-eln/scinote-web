class AddEmptyFieldToAsset < ActiveRecord::Migration[4.2]
  def up
    add_column :assets, :file_present, :boolean, default: false
    change_column_null :assets, :file_present, false
  end

  def down
    remove_column :assets, :file_present
  end
end
