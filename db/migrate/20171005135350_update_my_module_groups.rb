class UpdateMyModuleGroups < ActiveRecord::Migration[4.2]
  def change
    remove_column :my_module_groups, :name, :string
  end
end
