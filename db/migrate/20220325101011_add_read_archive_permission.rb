# frozen_string_literal: true

class AddReadArchivePermission < ActiveRecord::Migration[6.1]
  def change
    existing_role = UserRole.find_by(name: UserRole.public_send('viewer_role').name)
    if existing_role.present? && existing_role.permissions.exclude?(MyModulePermissions::READ_ARCHIVED)
      existing_role.permissions.push(MyModulePermissions::READ_ARCHIVED)
      existing_role.update_attribute(:permissions, existing_role.permissions)
    end
  end
end
