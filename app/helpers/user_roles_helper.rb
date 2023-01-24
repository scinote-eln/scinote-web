# frozen_string_literal: true

module UserRolesHelper
  def user_roles_collection(with_inherit: false)
    roles = UserRole.order(id: :asc).pluck(:name, :id)
    roles = [[t('access_permissions.reset'), 'reset']] + roles if with_inherit
    roles
  end

  def team_user_roles_collection
    team_permissions =
      PermissionExtends::TeamPermissions.constants.map { |const| TeamPermissions.const_get(const) } +
      ProtocolPermissions.constants.map { |const| ProtocolPermissions.const_get(const) } +
      RepositoryPermissions.constants.map { |const| RepositoryPermissions.const_get(const) }
    UserRole.where('permissions && ARRAY[?]::varchar[]', team_permissions)
            .sort_by { |user_role| (user_role.permissions & team_permissions).length }
            .reverse!
  end

  def team_user_roles_for_select
    team_user_roles_collection.pluck(:name, :id)
  end

  def managing_team_user_roles_collection
    UserRole.where('permissions && ARRAY[?]::varchar[]', [TeamPermissions::USERS_MANAGE])
  end
end
