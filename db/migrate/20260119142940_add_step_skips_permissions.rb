# frozen_string_literal: true

class AddStepSkipsPermissions < ActiveRecord::Migration[7.2]
  STEP_SKIPS_PERMISSIONS = [
    MyModulePermissions::STEPS_SKIP,
    MyModulePermissions::STEPS_UNSKIP
  ].freeze

  def up
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @technician_role = UserRole.find_predefined_technician_role

    @owner_role.permissions = @owner_role.permissions | STEP_SKIPS_PERMISSIONS
    @normal_user_role.permissions = @normal_user_role.permissions | STEP_SKIPS_PERMISSIONS
    @technician_role.permissions = @technician_role.permissions | STEP_SKIPS_PERMISSIONS

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
    @technician_role.save(validate: false)
  end

  def down
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @technician_role = UserRole.find_predefined_technician_role

    @owner_role.permissions = @owner_role.permissions - STEP_SKIPS_PERMISSIONS
    @normal_user_role.permissions = @normal_user_role.permissions - STEP_SKIPS_PERMISSIONS
    @technician_role.permissions = @technician_role.permissions - STEP_SKIPS_PERMISSIONS

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
    @technician_role.save(validate: false)
  end
end
