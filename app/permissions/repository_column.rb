# frozen_string_literal: true

Canaid::Permissions.register_for(RepositoryColumn) do
  # repository: update/delete field
  # Tested in scope of RepositoryPermissions spec
  can :manage_repository_column do |user, repository_column|
    managable = repository_column.repository.repository_snapshots.provisioning.none? &&
      can_create_repository_columns?(user, repository_column.repository)

    if repository_column.data_type == 'RepositoryStockValue'
      managable = can_manage_repository_stock?(user, repository_column.repository) && managable
    end

    managable
  end
end
