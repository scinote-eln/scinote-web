# frozen_string_literal: true

class MigrateToNewUserRoles < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        owner_role = UserRole.owner_role
        owner_role.save!
        normal_user_role = UserRole.normal_user_role
        normal_user_role.save!
        technician_role = UserRole.technician_role
        technician_role.save!
        viewer_role = UserRole.viewer_role
        viewer_role.save!

      end
      dir.down do
        UserAssignment.joins(:user_role).where(user_role: { predefined: true }).delete_all
        UserRole.where(predefined: true).delete_all
      end
    end
  end
end
