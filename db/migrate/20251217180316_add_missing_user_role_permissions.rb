# frozen_string_literal: true

class AddMissingUserRolePermissions < ActiveRecord::Migration[7.2]
  NORMAL_USER_PERMISSIONS = [
    ExperimentPermissions::READ_ARCHIVED,
    ExperimentPermissions::ACTIVITIES_READ
  ].freeze

  def change
    reversible do |dir|
      dir.up do
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @normal_user_role.permissions = @normal_user_role.permissions | NORMAL_USER_PERMISSIONS
        @normal_user_role.save(validate: false)
      end

      dir.down do
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @normal_user_role.permissions = @normal_user_role.permissions - NORMAL_USER_PERMISSIONS
        @normal_user_role.save(validate: false)
      end
    end
  end
end
