# frozen_string_literal: true

class AddStorageLocationPermissions < ActiveRecord::Migration[7.0]
  STORAGE_LOCATIONS_MANAGE_PERMISSION = [
    TeamPermissions::STORAGE_LOCATIONS_CREATE,
    TeamPermissions::STORAGE_LOCATIONS_MANAGE,
    TeamPermissions::STORAGE_LOCATION_CONTAINERS_CREATE,
    TeamPermissions::STORAGE_LOCATION_CONTAINERS_MANAGE
  ].freeze

  STORAGE_LOCATIONS_READ_PERMISSION = [
    TeamPermissions::STORAGE_LOCATIONS_READ,
    TeamPermissions::STORAGE_LOCATION_CONTAINERS_READ
  ].freeze

  def up
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @viewer_user_role = UserRole.find_predefined_viewer_role

    @owner_role.permissions = @owner_role.permissions | STORAGE_LOCATIONS_MANAGE_PERMISSION |
                              STORAGE_LOCATIONS_READ_PERMISSION
    @normal_user_role.permissions = @normal_user_role.permissions | STORAGE_LOCATIONS_MANAGE_PERMISSION |
                                    STORAGE_LOCATIONS_READ_PERMISSION
    @viewer_user_role.permissions = @viewer_user_role.permissions | STORAGE_LOCATIONS_READ_PERMISSION

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
    @viewer_user_role.save(validate: false)
  end

  def down
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role
    @viewer_user_role = UserRole.find_predefined_viewer_role

    @owner_role.permissions = @owner_role.permissions - STORAGE_LOCATIONS_MANAGE_PERMISSION -
                              STORAGE_LOCATIONS_READ_PERMISSION
    @normal_user_role.permissions = @normal_user_role.permissions - STORAGE_LOCATIONS_MANAGE_PERMISSION -
                                    STORAGE_LOCATIONS_READ_PERMISSION
    @viewer_user_role.permissions = @viewer_user_role.permissions - STORAGE_LOCATIONS_READ_PERMISSION

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
    @viewer_user_role.save(validate: false)
  end
end
