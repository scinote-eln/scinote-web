# frozen_string_literal: true

class AddEnforceTableStatePermission < ActiveRecord::Migration[7.2]
  ENFORCE_TABLE_STATE_PERMISSION = [
    RepositoryPermissions::ENFORCE_TABLE_STATE
  ].freeze

  def up
    owner_role = UserRole.find_predefined_owner_role
    owner_role.permissions = owner_role.permissions | ENFORCE_TABLE_STATE_PERMISSION
    owner_role.save(validate: false)
  end

  def down
    owner_role = UserRole.find_predefined_owner_role
    owner_role.permissions = owner_role.permissions - ENFORCE_TABLE_STATE_PERMISSION
    owner_role.save(validate: false)
  end
end
