# frozen_string_literal: true

Canaid::Permissions.register_for(RepositoryColumn) do
  # repository: update/delete field
  # Tested in scope of RepositoryPermissions spec
  can :manage_repository_column do |user, repository_column|
<<<<<<< HEAD
<<<<<<< HEAD
    repository_column.repository.repository_snapshots.provisioning.none? &&
      can_create_repository_columns?(user, repository_column.repository)
=======
    can_create_repository_columns?(user, repository_column.repository)
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    repository_column.repository.repository_snapshots.provisioning.none? &&
      can_create_repository_columns?(user, repository_column.repository)
>>>>>>> Pulled latest release
  end
end
