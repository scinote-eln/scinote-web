# frozen_string_literal: true

class AddTeamLevelPermissions < ActiveRecord::Migration[6.1]
  OWNER_PERMISSIONS = [
    TeamPermissions::READ,
    TeamPermissions::MANAGE,
    TeamPermissions::USERS_MANAGE,
    TeamPermissions::PROJECTS_CREATE,
    TeamPermissions::INVENTORIES_CREATE,
    TeamPermissions::PROTOCOLS_CREATE,
    ProtocolPermissions::READ,
    ProtocolPermissions::MANAGE,
    ProtocolPermissions::USERS_MANAGE,
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
    ProtocolPermissions::READ,
    ProtocolPermissions::MANAGE,
    RepositoryPermissions::READ,
    RepositoryPermissions::COLUMNS_CREATE,
    RepositoryPermissions::ROWS_CREATE,
    RepositoryPermissions::ROWS_UPDATE,
    RepositoryPermissions::ROWS_DELETE
  ].freeze

  VIEWER_PERMISSIONS = [ProtocolPermissions::READ].freeze

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

        UserAssignment.where(assignable_type: %w(Team Protocol Repository)).delete_all
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
    user_teams.includes(:user, team: %i(repositories repository_protocols))
              .find_in_batches(batch_size: 100) do |user_team_batch|
      user_assignments = []
      user_team_batch.each do |user_team|
        user_assignments << new_user_assignment(user_team.user, user_team.team, user_role, :manually)
        user_team.team.repositories.each do |repository|
          user_assignments << new_user_assignment(user_team.user, repository, user_role, :automatically)
        end
        user_team.team.repository_protocols.each do |protocol|
          if protocol.in_repository_private? && user_team.user_id == protocol.added_by_id
            user_assignments << new_user_assignment(user_team.user, protocol, @owner_role, :automatically)
          elsif protocol.in_repository_archived?
            if user_team.user_id == protocol.added_by_id
              user_assignments << new_user_assignment(user_team.user, protocol, @owner_role, :automatically)
            elsif protocol.published_on.present?
              user_assignments << new_user_assignment(user_team.user, protocol, @viewer_role, :automatically)
            end
          elsif protocol.in_repository_public?
            user_assignments << new_user_assignment(user_team.user, protocol, @viewer_role, :automatically)
          end
        end
      end
      UserAssignment.import(user_assignments)
    end
  end
end
