# frozen_string_literal: true

Canaid::Permissions.register_for(Repository) do
  # repository: read/export
  can :read_repository do |user, repository|
    if user.teams.include?(repository.team)
      user.is_member_of_team?(repository.team)
    elsif (read_team_repo = repository
                                .team_repositories
                                .where(team: user.teams).take)
      # When has some repository's relations with read permissions for at least one of user's teams.

      user.is_member_of_team?(read_team_repo.team)
    else
      false
    end
  end

  # repository: update, delete
  can :manage_repository do |user, repository|
    user.is_admin_of_team?(repository.team)
  end

  # repository: create/import record
  can :create_repository_rows do |user, repository|
    if user.teams.include?(repository.team)
      user.is_normal_user_or_admin_of_team?(repository.team)
    elsif (write_team_repos = repository
                                .team_repositories
                                .where(team_id: user.teams.pluck(:id))
                                .where(permission_level: :write)).any?
      # When has some repository's relations with write permissions for at least one of user's teams.

      user.is_normal_user_or_admin_of_team?(write_team_repos.first.team)
    else
      false
    end
  end

  # repository: update/delete records
  can :manage_repository_rows do |user, repository|
    can_create_repository_rows?(user, repository)
  end

  # repository: create field
  can :create_repository_columns do |user, repository|
    can_create_repository_rows?(user, repository)
  end
end
