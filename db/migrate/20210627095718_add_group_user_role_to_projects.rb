class AddGroupUserRoleToProjects < ActiveRecord::Migration[6.1]
  def change
    add_reference :projects, :group_user_role, foreign_key: { to_table: :user_roles }
  end
end
