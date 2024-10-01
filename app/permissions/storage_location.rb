# frozen_string_literal: true

Canaid::Permissions.register_for(StorageLocation) do
  can :read_storage_location do |user, storage_location|
    root_storage_location = storage_location.root_storage_location

    next true if root_storage_location.shared_with?(user.current_team)

    user.current_team == root_storage_location.team && root_storage_location.team.permission_granted?(
      user,
      if root_storage_location.container?
        TeamPermissions::STORAGE_LOCATION_CONTAINERS_READ
      else
        TeamPermissions::STORAGE_LOCATIONS_READ
      end
    )
  end

  can :manage_storage_location do |user, storage_location|
    root_storage_location = storage_location.root_storage_location

    next true if root_storage_location.shared_with_write?(user.current_team)

    user.current_team == root_storage_location.team && root_storage_location.team.permission_granted?(
      user,
      if root_storage_location.container?
        TeamPermissions::STORAGE_LOCATION_CONTAINERS_MANAGE
      else
        TeamPermissions::STORAGE_LOCATIONS_MANAGE
      end
    )
  end

  can :create_storage_location_repository_rows do |user, storage_location|
    can_read_storage_location?(user, storage_location)
  end

  can :share_storage_location do |user, storage_location|
    user.current_team == storage_location.team &&
      storage_location.root? &&
      can_manage_storage_location?(user, storage_location)
  end
end
