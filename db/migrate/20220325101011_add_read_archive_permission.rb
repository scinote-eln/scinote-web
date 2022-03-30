# frozen_string_literal: true

class AddReadArchivePermission < ActiveRecord::Migration[6.1]
  def up
    existing_role = UserRole.find_by(name: UserRole.public_send('viewer_role').name)
    existing_role&.update_attribute(:permissions, existing_role.permissions | [MyModulePermissions::READ_ARCHIVED])
  end

  def down
    existing_role = UserRole.find_by(name: UserRole.public_send('viewer_role').name)
    existing_role&.update_attribute(:permissions, existing_role.permissions - [MyModulePermissions::READ_ARCHIVED])
  end
end
