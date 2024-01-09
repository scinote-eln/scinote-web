# frozen_string_literal: true

Canaid::Permissions.register_for(RepositoryRow) do
  can :unlink_connection do |_, repository_row|
    !repository_row.archived?
  end
end
