# frozen_string_literal: true

Canaid::Permissions.register_for(RepositoryColumn) do
  # repository: update/delete field
  # Tested in scope of RepositoryPermissions spec
  can :manage_repository_column do |user, repository_column|
    can_create_repository_columns?(user, repository_column.repository)
  end
end
