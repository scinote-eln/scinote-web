# frozen_string_literal: true

Canaid::Permissions.register_for(RepositoryBase) do
  # repository: read/export
  can :read_repository do |user, repository|
    if repository.is_a?(RepositorySnapshot)
      user.teams.include?(repository.team)
    else
      user.teams.include?(repository.team) || repository.shared_with?(user.current_team)
    end
  end
end

Canaid::Permissions.register_for(Repository) do
  # Should be no provisioning snapshots for repository for all the specified permissions
  %i(manage_repository
     create_repository_rows
     manage_repository_rows
     update_repository_rows
     delete_repository_rows
     create_repository_columns)
    .each do |perm|
    can perm do |_, repository|
      repository.repository_snapshots.provisioning.none?
    end
  end

  # repository: update, delete
  can :manage_repository do |user, repository|
    user.is_admin_of_team?(repository.team) unless repository.shared_with?(user.current_team)
  end

  # repository: archive, restore
  can :archive_repository do |user, repository|
    next false if repository.is_a?(BmtRepository)

    !repository.shared_with?(user.current_team) && user.is_admin_of_team?(repository.team)
  end

  # repository: share
  can :share_repository do |user, repository|
    user.is_admin_of_team?(repository.team) unless repository.shared_with?(user.current_team)
  end

  # repository: make a snapshot with assigned rows
  can :create_repository_snapshot do |user, repository|
    user.is_normal_user_or_admin_of_team?(repository.team)
  end

  # repository: delete a snapshot with assigned rows
  can :delete_repository_snapshot do |user, repository|
    user.is_normal_user_or_admin_of_team?(repository.team)
  end

  # repository: create/import record
  can :create_repository_rows do |user, repository|
    next false if repository.is_a?(BmtRepository)

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

  # repository: create/update/delete filters
  can :manage_repository_filters do |user, repository|
    ((repository.team == user.current_team) && user.is_normal_user_or_admin_of_team?(repository.team)) ||
      (repository.shared_with_write?(user.current_team) && user.is_normal_user_or_admin_of_team?(user.current_team))
  end
end
