# TODO: For all permissions: foe ALL permission levels check whether they're
# archived (for restore permissions) or active (for all other permissions) -
# now we mostly do the check only for the permission level for which the
# permission was made
module Organization
  Canaid::Permissions.register_generic do
    # organization: create team
    can :create_teams do |_|
      true
    end
  end
end
