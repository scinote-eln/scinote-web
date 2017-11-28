Canaid::Permissions.register_for(Team) do
  # view projects
  can :read_team do |user, team|
    user.is_member_of_team?(team)
  end

  # invite user to team
  can :create_user_team do |user, team|
    user.is_admin_of_team?(team)
  end
end

Canaid::Permissions.register_for(UserTeam) do
  # change user's role, remove user from team, leave team
  can :update_or_delete_user_team do |user, user_team|
    user == user_team.user || user.is_admin_of_team?(user_team.team)
  end
end
