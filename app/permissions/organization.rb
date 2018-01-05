Canaid::Permissions.register_generic do
  can :create_teams do |user|
    true
  end
end
