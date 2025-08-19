# frozen_string_literal: true

class RemoveRepositoryColumnManagementPermissionsForNormalUserRole < ActiveRecord::Migration[7.2]
  REPOSITOY_COLUMN_MANAGE_PERMISSION = [
    RepositoryPermissions::COLUMNS_CREATE,
    RepositoryPermissions::COLUMNS_UPDATE,
    RepositoryPermissions::COLUMNS_DELETE
  ].freeze

  def up
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @normal_user_role.permissions = @normal_user_role.permissions - REPOSITOY_COLUMN_MANAGE_PERMISSION
    @normal_user_role.save(validate: false)
  end

  def down
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @normal_user_role.permissions = @normal_user_role.permissions | REPOSITOY_COLUMN_MANAGE_PERMISSION
    @normal_user_role.save(validate: false)
  end
end
