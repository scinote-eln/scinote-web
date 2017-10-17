class AddArchiveToMyModules < ActiveRecord::Migration
  def change
    add_column :my_modules, :archived, :boolean, { default: false, null: false }
    add_column :my_modules, :archived_on, :datetime
  end
end

