class RemoveUniqueOrganizationNameIndex < ActiveRecord::Migration
  def up
    remove_index :organizations, :name
    add_index :organizations, :name
  end

  def down
    remove_index :organizations, :name
    add_index :organizations, :name, unique: true
  end
end
