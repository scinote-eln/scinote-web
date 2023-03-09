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

        create_user_assignments(UserTeam.admin, @owner_role)
        create_user_assignments(UserTeam.normal_user, @normal_user_role)
        create_user_assignments(UserTeam.guest, @viewer_role)
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

  def create_user_assignments(user_teams, user_role)
    user_teams.includes(:user, team: %i(reports repositories repository_protocols))
              .find_in_batches(batch_size: 100) do |user_team_batch|
      user_assignments = []
      user_team_batch.each do |user_team|
        team_user_assignment = new_user_assignment(user_team.user, user_team.team, user_role, :manually)
        team_user_assignment.assign_attributes(created_at: user_team.created_at,
                                               updated_at: user_team.updated_at)
        user_assignments << team_user_assignment
        user_team.team.repositories.each do |repository|
          user_assignments << new_user_assignment(user_team.user, repository, user_role, :automatically)
        end
        user_team.team.repository_protocols.each do |protocol|
          if user_team.user_id == protocol.added_by_id
            user_assignments << new_user_assignment(user_team.user, protocol, @owner_role, :automatically)
          elsif (protocol.in_repository_archived? && protocol.published_on.present?) || protocol.in_repository_public?
            user_assignments << new_user_assignment(user_team.user, protocol, @viewer_role, :automatically)
          end
        end
        user_team.team.reports.each do |report|
          user_assignments << new_user_assignment(user_team.user, report, user_role, :automatically)
        end
      end
      UserAssignment.import(user_assignments)
    end
  end
end
