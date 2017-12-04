Canaid::Permissions.register_for(Team) do
  # view projects, view protocols
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

  # create protocol in repository, import protocol to repository
  can :create_protocol do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end

  # create sample, import sample
  can :create_sample do |user, team|
    user.is_normal_user_or_admin_of_team?(team)
  end
end

Canaid::Permissions.register_for(UserTeam) do
  # change user's role, remove user from team, leave team
  can :update_or_delete_user_team do |user, user_team|
    user == user_team.user || user.is_admin_of_team?(user_team.team)
  end
end
