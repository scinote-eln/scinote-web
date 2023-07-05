# frozen_string_literal: true

class AddShareableLinkPermissions < ActiveRecord::Migration[6.1]
  MY_MODULE_SHARE_PERMISSION = [
    MyModulePermissions::SHARE
  ].freeze

  def change
    reversible do |dir|
      dir.up do
        @owner_role = UserRole.find_predefined_owner_role
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @owner_role.permissions = @owner_role.permissions | MY_MODULE_SHARE_PERMISSION
        @normal_user_role.permissions = @normal_user_role.permissions | MY_MODULE_SHARE_PERMISSION
        @owner_role.save(validate: false)
        @normal_user_role.save(validate: false)
      end

      dir.down do
        @owner_role = UserRole.find_predefined_owner_role
        @normal_user_role = UserRole.find_predefined_normal_user_role
        @owner_role.permissions = @owner_role.permissions - MY_MODULE_SHARE_PERMISSION
        @normal_user_role.permissions = @normal_user_role.permissions - MY_MODULE_SHARE_PERMISSION
        @owner_role.save(validate: false)
        @normal_user_role.save(validate: false)
      end
    end
  end
end
