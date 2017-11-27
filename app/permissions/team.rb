Canaid::Permissions.register_for(Team) do
  can :read_team do |user, team|
    user.is_member_of_team?(team)
  end
end
