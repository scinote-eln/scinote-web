# frozen_string_literal: true

class AddFormResponsePermissions < ActiveRecord::Migration[7.0]
  FORM_RESPONSE_MANAGE_PERMISSION = [
    FormResponsePermissions::RESET,
    FormResponsePermissions::CREATE
  ].freeze

  FORM_RESPONSE_SUBMIT_PERMISSION = [
    FormResponsePermissions::SUBMIT
  ].freeze

  def up
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @technician_user_role = UserRole.find_predefined_technician_role

    @owner_role.permissions = @owner_role.permissions | (FORM_RESPONSE_SUBMIT_PERMISSION + FORM_RESPONSE_MANAGE_PERMISSION)
    @normal_user_role.permissions = @normal_user_role.permissions | (FORM_RESPONSE_SUBMIT_PERMISSION + FORM_RESPONSE_MANAGE_PERMISSION)
    @technician_user_role.permissions = @technician_user_role.permissions | FORM_RESPONSE_SUBMIT_PERMISSION

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
    @technician_user_role.save(validate: false)
  end

  def down
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @technician_user_role = UserRole.find_predefined_technician_role

    @owner_role.permissions = @owner_role.permissions - (FORM_RESPONSE_SUBMIT_PERMISSION + FORM_RESPONSE_MANAGE_PERMISSION)
    @normal_user_role.permissions = @normal_user_role.permissions - (FORM_RESPONSE_SUBMIT_PERMISSION + FORM_RESPONSE_MANAGE_PERMISSION)
    @technician_user_role.permissions = @technician_user_role.permissions - FORM_RESPONSE_SUBMIT_PERMISSION

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
    @technician_user_role.save(validate: false)
  end
end
