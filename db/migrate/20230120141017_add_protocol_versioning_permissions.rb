# frozen_string_literal: true

class AddProtocolVersioningPermissions < ActiveRecord::Migration[6.1]
  OWNER_PERMISSIONS = [
    ProtocolPermissions::MANAGE_DRAFT
  ].freeze

  NORMAL_USER_PERMISSIONS = [
    ProtocolPermissions::MANAGE_DRAFT
  ].freeze

  REMOVED_NORMAL_USER_PERMISSIONS = [
    ProtocolPermissions::MANAGE
  ].freeze

  def change
    reversible do |dir|
      dir.up do
        @owner_role = UserRole.find_predefined_owner_role
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @owner_role.permissions = @owner_role.permissions | OWNER_PERMISSIONS
        @normal_user_role.permissions = @normal_user_role.permissions | NORMAL_USER_PERMISSIONS
        @normal_user_role.permissions = @normal_user_role.permissions - REMOVED_NORMAL_USER_PERMISSIONS
        @owner_role.save(validate: false)
        @normal_user_role.save(validate: false)

        # properly assign protocol owners, who must always be marked as assigned manually
        UserAssignment.where(
          assignable_type: 'Protocol',
          user_role: UserRole.find_predefined_owner_role,
          assigned: :automatically
        ).update_all(assigned: :manually)
      end

      dir.down do
        @owner_role = UserRole.find_predefined_owner_role
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @owner_role.permissions = @owner_role.permissions - OWNER_PERMISSIONS
        @normal_user_role.permissions = @normal_user_role.permissions - NORMAL_USER_PERMISSIONS
        @normal_user_role.permissions = @normal_user_role.permissions | REMOVED_NORMAL_USER_PERMISSIONS
        @owner_role.save(validate: false)
        @normal_user_role.save(validate: false)
      end
    end
  end
end
