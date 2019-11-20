# frozen_string_literal: true

Canaid::Permissions.register_for(Repository) do
  # repository: read/export
  can :read_repository do |user, repository|
    user.teams.include?(repository.team) || repository.shared_with?(user.current_team)
  end

  # repository: update, delete
  can :manage_repository do |user, repository|
    user.is_admin_of_team?(repository.team) unless repository.shared_with?(user.current_team)
  end

  # repository: share
  can :share_repository do |user, repository|
    user.is_admin_of_team?(repository.team) unless repository.shared_with?(user.current_team)
  end

  # repository: create/import record
  can :create_repository_rows do |user, repository|
    if repository.shared_with?(user.current_team)
      repository.shared_with_write?(user.current_team) && user.is_normal_user_or_admin_of_team?(user.current_team)
    elsif user.teams.include?(repository.team)
      user.is_normal_user_or_admin_of_team?(repository.team)
    end
  end

  # repository: update/delete records
  can :manage_repository_rows do |user, repository|
    can_create_repository_rows?(user, repository)
  end

  can :update_repository_rows do |user, repository|
    can_manage_repository_rows?(user, repository)
  end

  can :delete_repository_rows do |user, repository|
    can_manage_repository_rows?(user, repository)
  end

  # repository: create field
  can :create_repository_columns do |user, repository|
    can_create_repository_rows?(user, repository) unless repository.shared_with?(user.current_team)
  end
end
