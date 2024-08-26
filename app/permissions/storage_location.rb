# frozen_string_literal: true

Canaid::Permissions.register_for(StorageLocation) do
  can :read_storage_location do |user, storage_location|
    storage_location.team.permission_granted?(
      user,
      if @storage_location.container
        TeamPermissions::STORAGE_LOCATION_CONTAINERS_READ
      else
        TeamPermissions::STORAGE_LOCATIONS_READ
      end
    )
  end

  can :manage_storage_location do |user, storage_location|
    storage_location.team.permission_granted?(
      user,
      if @storage_location.container
        TeamPermissions::STORAGE_LOCATION_CONTAINERS_MANAGE
      else
        TeamPermissions::STORAGE_LOCATIONS_MANAGE
      end
    )
  end

  can :share_storage_location do |user, storage_location|
    storage_location.team.permission_granted?(user, TeamPermissions::STORAGE_LOCATIONS_MANAGE)
  end
end
