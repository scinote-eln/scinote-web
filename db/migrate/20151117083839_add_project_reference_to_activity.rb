class AddProjectReferenceToActivity < ActiveRecord::Migration[4.2]
  def up
    # Make my module reference nullable
    change_column_null :activities, :my_module_id, true

    # Add reference to project
    add_reference :activities, :project, index: true
    add_foreign_key :activities, :projects

    # Update existing entries so they all have project reference
    Activity.all.each do |activity|
      if activity.present? and
        activity.my_module.present? and
        activity.my_module.project.present? then
        activity.project = activity.my_module.project
        activity.save
      end
    end

    # Make project reference non-nullable
    change_column_null :activities, :project_id, false
  end

  def down
    # Unfortunately, all activities that are bound to project
    # need to be deleted since they're not "compatible" in the previous
    # version of the DB
    Activity.destroy_all(my_module: nil)

    remove_foreign_key :activities, :projects
    remove_reference :activities, :project, index: true
    change_column_null :activities, :my_module_id, false
  end
end
