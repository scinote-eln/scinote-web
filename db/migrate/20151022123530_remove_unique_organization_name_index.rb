class RemoveUniqueOrganizationNameIndex < ActiveRecord::Migration
  def up
    remove_index :teams, :name
    add_index :teams, :name
  end

  def down
    remove_index :teams, :name
    add_index :teams, :name, unique: true
  end
end
