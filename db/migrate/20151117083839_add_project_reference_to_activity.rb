class AddProjectReferenceToActivity < ActiveRecord::Migration[4.2]
  def up
    # Make my module reference nullable
    change_column_null :activities, :my_module_id, true

    # Add reference to project
    add_reference :activities, :project, index: true
    add_foreign_key :activities, :projects

    # Make project reference non-nullable
    change_column_null :activities, :project_id, false
  end

  def down
    remove_foreign_key :activities, :projects
    remove_reference :activities, :project, index: true
    change_column_null :activities, :my_module_id, false
  end
end
