# frozen_string_literal: true

class AddMissingRepositoryAndProtocolPermissions < ActiveRecord::Migration[6.1]
  OWNER_PERMISSIONS = [ProtocolPermissions::READ_ARCHIVED].freeze
  NORMAL_USER_PERMISSIONS = [ProtocolPermissions::READ_ARCHIVED].freeze
  VIEWER_PERMISSIONS = [ProtocolPermissions::READ_ARCHIVED,
                        RepositoryPermissions::READ,
                        RepositoryPermissions::READ_ARCHIVED].freeze

  def change
    reversible do |dir|
      dir.up do
        owner_role = UserRole.find_predefined_owner_role
        normal_user_role = UserRole.find_predefined_normal_user_role
        viewer_role = UserRole.find_predefined_viewer_role

        owner_role.permissions = owner_role.permissions | OWNER_PERMISSIONS
        owner_role.save(validate: false)
        normal_user_role.permissions = normal_user_role.permissions | NORMAL_USER_PERMISSIONS
        normal_user_role.save(validate: false)
        viewer_role.permissions = viewer_role.permissions | VIEWER_PERMISSIONS
        viewer_role.save(validate: false)
      end

      dir.down do
        owner_role = UserRole.find_predefined_owner_role
        normal_user_role = UserRole.find_predefined_normal_user_role
        viewer_role = UserRole.find_predefined_viewer_role

        owner_role.permissions = owner_role.permissions - OWNER_PERMISSIONS
        owner_role.save(validate: false)
        normal_user_role.permissions = normal_user_role.permissions - NORMAL_USER_PERMISSIONS
        normal_user_role.save(validate: false)
        viewer_role.permissions = viewer_role.permissions - VIEWER_PERMISSIONS
        viewer_role.save(validate: false)
      end
    end
  end
end
