class UpdateMyModuleGroups < ActiveRecord::Migration
  def change
    remove_column :my_module_groups, :name, :string
  end
end
