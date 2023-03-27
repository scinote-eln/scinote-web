class AddIndexToMyModules < ActiveRecord::Migration[6.1]
  def change
    add_index :my_modules, :archived
  end
end
