# frozen_string_literal: true

class AddMissingRepositoryPermissions < ActiveRecord::Migration[6.1]
  NORMAL_USER_PERMISSIONS = [
    RepositoryPermissions::COLUMNS_UPDATE,
    RepositoryPermissions::COLUMNS_DELETE
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
