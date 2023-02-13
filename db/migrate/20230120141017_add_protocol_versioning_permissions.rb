# frozen_string_literal: true

class AddProtocolVersioningPermissions < ActiveRecord::Migration[6.1]
  OWNER_PERMISSIONS = [
    ProtocolPermissions::MANAGE_DRAFT
  ].freeze

  NORMAL_USER_PERMISSIONS = [
    ProtocolPermissions::MANAGE_DRAFT
  ].freeze

  def change
    reversible do |dir|
      dir.up do
        @owner_role = UserRole.find_predefined_owner_role
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @owner_role.permissions = @owner_role.permissions | OWNER_PERMISSIONS
        @normal_user_role.permissions = @normal_user_role.permissions | NORMAL_USER_PERMISSIONS
        @owner_role.save(validate: false)
        @normal_user_role.save(validate: false)
      end

      dir.down do
        @owner_role = UserRole.find_predefined_owner_role
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @owner_role.permissions = @owner_role.permissions - OWNER_PERMISSIONS
        @normal_user_role.permissions = @normal_user_role.permissions - NORMAL_USER_PERMISSIONS
        @owner_role.save(validate: false)
        @normal_user_role.save(validate: false)
      end
    end
  end
end
