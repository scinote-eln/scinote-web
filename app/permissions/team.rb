Canaid::Permissions.register_for(Team) do
  # team: leave, read users, read projects, read/export samples,
  #       read protocols, read/export repositories
  #
  can :read_team do |user, team|
    user.is_member_of_team?(team)
  end

  # team: update
  can :update_team do |user, team|
    user.is_admin_of_team?(team)
  end

  # team: assign/unassing user, change user role
  can :manage_team_users do |user, team|
    user.is_admin_of_team?(team)
  end

  # project: create
  can :create_projects do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # protocol in repository: create, import
  can :create_protocols_in_repository do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # sample: create, import
  can :create_samples do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # sample: create field
  can :create_sample_columns do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # create/update/delete sample type/group
  can :manage_sample_types_and_groups do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # repository: create, copy
  can :create_repositories do |user, team|
    user.is_admin_of_team?(team) &&
      team.repositories.count < Constants::REPOSITORIES_LIMIT
  end

  # repository: create/import record
  can :create_repository_rows do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # repository: create field
  can :create_repository_columns do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end
end

Canaid::Permissions.register_for(Protocol) do
  # protocol in repository: read, export, read step, read/download step asset
  can :read_protocol_in_repository do |user, protocol|
    user.is_member_of_team?(protocol.team) &&
      (protocol.in_repository_public? ||
      protocol.in_repository_private? && user == protocol.added_by)
  end

  # protocol in repository: update, create/update/delete/reorder step,
  #                         toggle private/public visibility, archive
  can :manage_protocol_in_repository do |user, protocol|
    protocol.in_repository_active? &&
      user.is_normal_user_or_admin_of_team?(protocol.team) &&
      user == protocol.added_by
  end

  # protocol in repository: restore
  can :restore_protocol_in_repository do |user, protocol|
    protocol.in_repository_archived? &&
      user.is_normal_user_or_admin_of_team?(protocol.team) &&
      user == protocol.added_by
  end

  # protocol in repository: copy
  can :clone_protocol_in_repository do |user, protocol|
    can_read_protocol_in_repository?(user, protocol) &&
      can_create_protocols_in_repository?(user, protocol.team)
  end
end

Canaid::Permissions.register_for(Sample) do
  # sample: update, delete
  can :manage_sample do |user, sample|
    can_create_samples?(user, sample.team)
  end
end

Canaid::Permissions.register_for(CustomField) do
  # sample: update/delete field
  can :manage_sample_column do |user, custom_field|
    custom_field.sample_custom_fields.all? do |sample_custom_field|
      can_create_sample_columns?(user, sample_custom_field.sample)
    end
  end
end

Canaid::Permissions.register_for(Repository) do
  # repository: update, delete
  can :manage_repository do |user, repository|
    can_create_repositories?(user, repository.team)
  end
end

Canaid::Permissions.register_for(RepositoryRow) do
  # repository: update/delete record
  can :manage_repository_row do |user, repository_row|
    can_create_repository_rows?(user, repository_row.repository.team)
  end
end

Canaid::Permissions.register_for(RepositoryColumn) do
  # repository: update/delete field
  can :manage_repository_column do |user, repository_column|
    can_create_repository_columns?(user, repository_column.repository.team)
  end
end
