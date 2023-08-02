# frozen_string_literal: true

class AddTeamLevelPermissions < ActiveRecord::Migration[6.1]
  class UserAssignment < ApplicationRecord
    self.table_name = 'user_assignments'
    belongs_to :assignable, polymorphic: true, touch: true
    belongs_to :user_role
    belongs_to :user
    belongs_to :assigned_by, class_name: 'User', optional: true

    enum assigned: { automatically: 0, manually: 1 }, _suffix: true

    validates :user, uniqueness: { scope: %i(assignable) }
  end

  OWNER_PERMISSIONS = [
    TeamPermissions::READ,
    TeamPermissions::MANAGE,
    TeamPermissions::USERS_MANAGE,
    TeamPermissions::PROJECTS_CREATE,
    TeamPermissions::INVENTORIES_CREATE,
    TeamPermissions::PROTOCOLS_CREATE,
    TeamPermissions::REPORTS_CREATE,
    ProtocolPermissions::READ,
    ProtocolPermissions::MANAGE,
    ProtocolPermissions::USERS_MANAGE,
    ReportPermissions::READ,
    ReportPermissions::MANAGE,
    ReportPermissions::USERS_MANAGE,
    RepositoryPermissions::READ,
    RepositoryPermissions::READ_ARCHIVED,
    RepositoryPermissions::MANAGE,
    RepositoryPermissions::DELETE,
    RepositoryPermissions::SHARE,
    RepositoryPermissions::ROWS_CREATE,
    RepositoryPermissions::ROWS_UPDATE,
    RepositoryPermissions::ROWS_DELETE,
    RepositoryPermissions::COLUMNS_CREATE,
    RepositoryPermissions::COLUMNS_UPDATE,
    RepositoryPermissions::COLUMNS_DELETE,
    RepositoryPermissions::USERS_MANAGE
  ].freeze

  NORMAL_USER_PERMISSIONS = [
    TeamPermissions::PROJECTS_CREATE,
    TeamPermissions::PROTOCOLS_CREATE,
    TeamPermissions::REPORTS_CREATE,
    ProtocolPermissions::READ,
    ProtocolPermissions::MANAGE,
    ReportPermissions::READ,
    ReportPermissions::MANAGE,
    RepositoryPermissions::READ,
    RepositoryPermissions::COLUMNS_CREATE,
    RepositoryPermissions::ROWS_CREATE,
    RepositoryPermissions::ROWS_UPDATE,
    RepositoryPermissions::ROWS_DELETE
  ].freeze

  VIEWER_PERMISSIONS = [ProtocolPermissions::READ, ReportPermissions::READ].freeze

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

        UserAssignment.where(assignable_type: %w(Team Protocol Report RepositoryBase)).delete_all
      end
    end
  end

  private

  def new_user_assignment(user, assignable, user_role, assigned)
    UserAssignment.new(
      user: user,
      assignable: assignable,
      assigned: assigned,
      user_role: user_role
    )
  end
end
