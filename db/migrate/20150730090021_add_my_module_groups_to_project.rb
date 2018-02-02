class AddMyModuleGroupsToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :my_module_groups, :project_id, :integer

    # Update current module groups
    MyModuleGroup.all.each do |my_module_group|
      if my_module_group.my_modules.present? then
        my_module_group.project_id = my_module_group.my_modules.first.project.id
        my_module_group.save
      end
    end

    # Now make column non-nullable
    change_column :my_module_groups, :project_id, :integer, :null => false
    add_foreign_key :my_module_groups, :projects
    add_index :my_module_groups, :project_id
  end
end
