# frozen_string_literal: true

class RemoveExperimentTaskManagePermissions < ActiveRecord::Migration[6.1]
  TASKS_MANAGE_PERMISSION = %w(experiment_tasks_manage).freeze
  TASKS_CREATE_PERMISSION = %w(experiment_tasks_create).freeze

  def change
    reversible do |dir|
      dir.up do
        owner_role = UserRole.find_predefined_owner_role
        normal_user_role = UserRole.find_predefined_normal_user_role

        owner_role.permissions = (owner_role.permissions - TASKS_MANAGE_PERMISSION) | TASKS_CREATE_PERMISSION
        owner_role.save(validate: false)
        normal_user_role.permissions = (normal_user_role.permissions - TASKS_MANAGE_PERMISSION) |
                                       TASKS_CREATE_PERMISSION
        normal_user_role.save(validate: false)
      end

      dir.down do
        owner_role = UserRole.find_predefined_owner_role
        normal_user_role = UserRole.find_predefined_normal_user_role

        owner_role.permissions = (owner_role.permissions | TASKS_MANAGE_PERMISSION) - TASKS_CREATE_PERMISSION
        owner_role.save(validate: false)
        normal_user_role.permissions = (normal_user_role.permissions | TASKS_MANAGE_PERMISSION) -
                                       TASKS_CREATE_PERMISSION
        normal_user_role.save(validate: false)
      end
    end
  end
end
