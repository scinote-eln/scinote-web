class AddLabelTemplatesPermissions < ActiveRecord::Migration[6.1]
 # frozen_string_literal: true
  OWNER_PERMISSIONS = [
    TeamPermissions::LABEL_TEMPLATES_READ,
    TeamPermissions::LABEL_TEMPLATES_MANAGE
  ].freeze

  NORMAL_USER_PERMISSIONS = [
    TeamPermissions::LABEL_TEMPLATES_READ,
    TeamPermissions::LABEL_TEMPLATES_MANAGE
  ].freeze

  VIEWER_PERMISSIONS = [TeamPermissions::LABEL_TEMPLATES_READ].freeze

  def change
    reversible do |dir|
      dir.up do
        @owner_role = UserRole.find_by(name: UserRole.public_send('owner_role').name)
        @normal_user_role = UserRole.find_by(name: UserRole.public_send('normal_user_role').name)
        @viewer_role = UserRole.find_by(name: UserRole.public_send('viewer_role').name)

        @owner_role.permissions = @owner_role.permissions | OWNER_PERMISSIONS
        @owner_role.save(validate: false)
        @normal_user_role.permissions = @normal_user_role.permissions | NORMAL_USER_PERMISSIONS
        @normal_user_role.save(validate: false)
        @viewer_role.permissions = @viewer_role.permissions | VIEWER_PERMISSIONS
        @viewer_role.save(validate: false)
      end

      dir.down do
        @owner_role = UserRole.find_by(name: UserRole.public_send('owner_role').name)
        @normal_user_role = UserRole.find_by(name: UserRole.public_send('normal_user_role').name)
        @viewer_role = UserRole.find_by(name: UserRole.public_send('viewer_role').name)

        @owner_role.permissions = @owner_role.permissions - OWNER_PERMISSIONS
        @owner_role.save(validate: false)
        @normal_user_role.permissions = @normal_user_role.permissions - NORMAL_USER_PERMISSIONS
        @normal_user_role.save(validate: false)
        @viewer_role.permissions = @viewer_role.permissions - VIEWER_PERMISSIONS
        @viewer_role.save(validate: false)
      end
    end
  end
end
