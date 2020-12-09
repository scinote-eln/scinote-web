class AddRapTaskLevelToProject < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :rap_task_level_id, :integer

    #Update current projects
    Project.all.each do |project|
      # This could probably be written in a safer manner by selecting an ID that is sure to exist.
      project.rap_task_level_id = 1
      project.save
    end

    # Now make the column non-nullable, add foreign key reference, and add index on the new FK id
    change_column :projects, :rap_task_level_id, :integer, :null => false
    add_foreign_key :projects, :rap_task_levels
    add_index :projects, :rap_task_level_id
  end
end
