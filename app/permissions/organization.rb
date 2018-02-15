Canaid::Permissions.register_generic do
  # organization: create team
  can :create_teams do |_|
    true
  end
end
