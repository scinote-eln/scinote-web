# frozen_string_literal: true

Canaid::Permissions.register_for(RepositoryBase) do
  # repository: read/export
  can :read_repository do |user, repository|
    if repository.is_a?(RepositorySnapshot)
      can_read_my_module?(user, repository.my_module)
    else
      user.teams.include?(repository.team) || repository.shared_with?(user.current_team)
    end
  end

  can :export_repository_stock do |user, repository|
    if repository.is_a?(Repository)
      can_read_repository?(user, repository) && repository.has_stock_management?
    else
      false
    end
  end
end

Canaid::Permissions.register_for(Repository) do
  # Should be no provisioning snapshots for repository for all the specified permissions
  %i(manage_repository
     create_repository_rows
     manage_repository_rows
     delete_repository_rows
     create_repository_columns)
    .each do |perm|
    can perm do |_, repository|
      repository.active? && repository.repository_snapshots.provisioning.none?
    end
  end

  %i(create_repository_rows
     manage_repository_rows
     manage_repository_assets
     delete_repository_rows)
    .each do |perm|
    can perm do |user, repository|
      repository.shared_with?(user.current_team) ? repository.shared_with_write?(user.current_team) : true
    end
  end

  # repository: update, delete
  can :manage_repository do |user, repository|
    !repository.shared_with?(user.current_team) && repository.permission_granted?(user, RepositoryPermissions::MANAGE)
  end

  # repository: archive, restore
  can :archive_repository do |user, repository|
    !repository.shared_with?(user.current_team) && repository.permission_granted?(user, RepositoryPermissions::MANAGE)
  end

  # repository: destroy
  can :delete_repository do |user, repository|
    repository.archived? && repository.permission_granted?(user, RepositoryPermissions::MANAGE)
  end

  # repository: share
  can :share_repository do |user, repository|
    !repository.shared_with?(user.current_team) && repository.permission_granted?(user, RepositoryPermissions::SHARE)
  end

  # repository: make a snapshot with assigned rows
  can :create_repository_snapshot do |user, repository|
    can_read_repository?(user, repository)
  end

  # repository: delete a snapshot with assigned rows
  can :delete_repository_snapshot do |user, repository|
    can_manage_repository?(user, repository)
  end

  # repository: create/import record
  can :create_repository_rows do |user, repository|
    next false if repository.archived?

    repository.permission_granted?(user, RepositoryPermissions::ROWS_CREATE)
  end

  can :manage_repository_assets do |user, repository|
    repository.permission_granted?(user, RepositoryPermissions::ROWS_UPDATE)
  end

  # repository: update/delete records
  can :manage_repository_rows do |user, repository|
    repository.permission_granted?(user, RepositoryPermissions::ROWS_UPDATE)
  end

  # create row connections
  can :connect_repository_rows do |user, repository|
    repository.repository_snapshots.provisioning.none? &&
      repository.permission_granted?(user, RepositoryPermissions::ROWS_UPDATE)
  end

  can :delete_repository_rows do |user, repository|
    repository.permission_granted?(user, RepositoryPermissions::ROWS_DELETE)
  end

  # repository: create field
  can :create_repository_columns do |user, repository|
    !repository.shared_with?(user.current_team) &&
      repository.permission_granted?(user, RepositoryPermissions::COLUMNS_CREATE)
  end

  # repository: create/update/delete filters
  can :manage_repository_filters do |user, repository|
    repository.permission_granted?(user, RepositoryPermissions::FILTERS_MANAGE)
  end

  can :manage_repository_stock do |user, repository|
    RepositoryBase.stock_management_enabled? && can_manage_repository_rows?(user, repository)
  end
end
