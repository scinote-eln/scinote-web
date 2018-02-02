class RemoveDefaultUserProjectRoleValue < ActiveRecord::Migration[4.2]
  def up
    change_column_default(:user_projects, :role, nil)
  end

  def down
    change_column_default(:user_projects, :role, 0)
  end
end
