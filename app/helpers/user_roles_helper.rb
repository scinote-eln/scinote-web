# frozen_string_literal: true

module UserRolesHelper
  def user_roles_collection(object, with_inherit: false)
    permission_group = "#{object.class.name}Permissions".constantize
    permissions = permission_group.constants.map { |const| permission_group.const_get(const) }

    roles = user_roles_subset_by_permissions(permissions).order(id: :asc).pluck(:name, :id)
    if with_inherit
      roles = [[t('access_permissions.reset'), 'reset',
                t("access_permissions.partials.#{object.class.name.underscore}_member_field.reset_description")]] +
              roles
    end
    roles
  end

  def team_user_roles_collection
    team_permissions =
      PermissionExtends::TeamPermissions.constants.map { |const| TeamPermissions.const_get(const) } +
      ProtocolPermissions.constants.map { |const| ProtocolPermissions.const_get(const) } +
      RepositoryPermissions.constants.map { |const| RepositoryPermissions.const_get(const) }

    user_roles_subset_by_permissions(team_permissions)
      .sort_by { |user_role| (user_role.permissions & team_permissions).length }
      .reverse!
  end

  def team_user_roles_for_select
    team_user_roles_collection.pluck(:name, :id)
  end

  def managing_team_user_roles_collection
    user_roles_subset_by_permissions([TeamPermissions::USERS_MANAGE])
  end

  private

  def user_roles_subset_by_permissions(permissions)
    UserRole.where('permissions && ARRAY[?]::varchar[]', permissions)
  end
end
