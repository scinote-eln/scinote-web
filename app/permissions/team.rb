Canaid::Permissions.register_for(Team) do
  # view projects, view protocols
  # view samples, export samples
  # view repositories, view repository, export repository rows
  can :read_team do |user, team|
    user.is_member_of_team?(team)
  end

  # edit team name, edit team description
  can :update_team do |user, team|
    user.is_admin_of_team?(team)
  end

  # invite user to team
  can :create_user_team do |user, team|
    user.is_admin_of_team?(team)
  end

  # create project
  can :create_project do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # create protocol in repository, import protocol to repository
  can :create_protocol do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # create, import, edit, delete sample
  can :manage_sample do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # create, update, delete custom field, sample type and sample group
  can :manage_sample_elements do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # create, import, edit, delete repository record
  can :manage_repository_row do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # create, update, delete repository column
  can :manage_repository_column do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end
end

Canaid::Permissions.register_for(UserTeam) do
  # change user's role, remove user from team, leave team
  can :update_or_delete_user_team do |user, user_team|
    user == user_team.user || user.is_admin_of_team?(user_team.team)
  end
end

Canaid::Permissions.register_for(Protocol) do
  # view protocol in repository, export protocol from repository
  # view step in protocol in repository, view or dowload step asset
  can :read_protocol_in_repository do |user, protocol|
    user.is_member_of_team?(protocol.team) &&
      (protocol.in_repository_public? ||
      protocol.in_repository_private? && user == protocol.added_by)
  end

  # edit protocol in repository,
  # create, edit, delete or reorder step in repository
  can :update_protocol_in_repository do |user, protocol|
    protocol.in_repository_active? &&
      can_update_protocol_type_in_repository?(user, protocol)
  end

  # toggle protocol visibility (public, private, archive, restore)
  can :update_protocol_type_in_repository do |user, protocol|
    user.is_normal_user_or_admin_of_team?(protocol.team) &&
      user == protocol.added_by
  end

  # clone protocol in repository
  can :clone_protocol do |user, protocol|
    can_create_protocol?(user, protocol.team) &&
      can_read_protocol_in_repository?(user, protocol)
  end
end
