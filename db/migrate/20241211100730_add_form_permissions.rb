# frozen_string_literal: true

class AddFormPermissions < ActiveRecord::Migration[7.0]
  FORM_MANAGE_PERMISSION = [
    TeamPermissions::FORMS_CREATE,
    FormPermissions::READ,
    FormPermissions::READ_ARCHIVED,
    FormPermissions::MANAGE
  ].freeze

  FORM_READ_PERMISSION = [
    FormPermissions::READ,
    FormPermissions::READ_ARCHIVED
  ].freeze

  def up
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @viewer_user_role = UserRole.find_predefined_viewer_role

    @owner_role.permissions = @owner_role.permissions | (FORM_MANAGE_PERMISSION + [FormPermissions::USERS_MANAGE]) |
                              FORM_READ_PERMISSION
    @normal_user_role.permissions = @normal_user_role.permissions | FORM_MANAGE_PERMISSION |
                                    FORM_READ_PERMISSION
    @viewer_user_role.permissions = @viewer_user_role.permissions | FORM_READ_PERMISSION

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
    @viewer_user_role.save(validate: false)
  end

  def down
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @viewer_user_role = UserRole.find_predefined_viewer_role

    @owner_role.permissions = @owner_role.permissions - FORM_MANAGE_PERMISSION -
                              FORM_READ_PERMISSION - [FormPermissions::USERS_MANAGE]
    @normal_user_role.permissions = @normal_user_role.permissions - FORM_MANAGE_PERMISSION -
                                    FORM_READ_PERMISSION
    @viewer_user_role.permissions = @viewer_user_role.permissions - FORM_READ_PERMISSION

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
    @viewer_user_role.save(validate: false)
  end
end
