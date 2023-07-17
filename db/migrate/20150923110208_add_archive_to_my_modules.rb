class AddArchiveToMyModules < ActiveRecord::Migration[4.2]
  def change
    add_column :my_modules, :archived, :boolean, default: false, null: false
    add_column :my_modules, :archived_on, :datetime
  end
end
