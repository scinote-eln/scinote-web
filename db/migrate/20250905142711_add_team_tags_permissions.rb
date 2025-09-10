# frozen_string_literal: true

class AddTeamTagsPermissions < ActiveRecord::Migration[7.2]
  TEAM_TAGS_OWNER_PERMISSIONS = [
    TeamPermissions::TAGS_CREATE,
    TeamPermissions::TAGS_UPDATE,
    TeamPermissions::TAGS_DELETE
  ].freeze

  TEAM_TAGS_NORMAL_USER_PERMISSIONS = [
    TeamPermissions::TAGS_CREATE,
    TeamPermissions::TAGS_UPDATE
  ].freeze

  def up
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role

    @owner_role.permissions = @owner_role.permissions | TEAM_TAGS_OWNER_PERMISSIONS
    @normal_user_role.permissions = @normal_user_role.permissions | TEAM_TAGS_NORMAL_USER_PERMISSIONS

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
  end

  def down
    @owner_role = UserRole.find_predefined_owner_role
    @normal_user_role = UserRole.find_predefined_normal_user_role

    @owner_role.permissions = @owner_role.permissions - TEAM_TAGS_OWNER_PERMISSIONS
    @normal_user_role.permissions = @normal_user_role.permissions - TEAM_TAGS_NORMAL_USER_PERMISSIONS

    @owner_role.save(validate: false)
    @normal_user_role.save(validate: false)
  end
end
