# frozen_string_literal: true

module Lists
  class RepositorySerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers
    include ShareableSerializer

    attributes :name, :code, :nr_of_rows, :team, :created_at, :created_by, :archived_on, :archived_by,
               :urls, :top_level_assignable, :default_public_user_role_id, :assigned_users, :permissions

    def default_public_user_role_id
      object.default_public_user_role_id(current_user.current_team)
    end

    def nr_of_rows
      object[:repository_rows_count]
    end

    def team
      current_user.current_team.name
    end

    def created_at
      I18n.l(object.created_at, format: :full)
    end

    def created_by
      object[:created_by_user]
    end

    def archived_on
      I18n.l(object.archived_on, format: :full) if object.archived_on
    end

    def archived_by
      object[:archived_by_user]
    end

    def assigned_users
      users = object.user_assignments.map do |ua|
        {
          avatar: avatar_path(ua.user, :icon_small),
          full_name: ua.user_name_with_role
        }
      end

      user_groups = object.user_group_assignments.map do |ua|
        {
          avatar: ActionController::Base.helpers.asset_path('icon/group.svg'),
          full_name: ua.user_group_name_with_role
        }
      end

      users + user_groups
    end

    def permissions
      {
        manage_users_assignments: can_manage_repository_users?(object)
      }
    end

    def urls
      urls = {
        show: repository_path(object),
        update: team_repository_path(current_user.current_team, id: object, format: :json),
        duplicate: team_repository_copy_path(current_user.current_team, repository_id: object, format: :json),
        shareable_teams: shareable_teams_team_shared_objects_path(
          current_user.current_team, object_id: object.id, object_type: 'Repository'
        ),
        show_access: access_permissions_repository_path(object),
        share: team_shared_objects_path(current_user.current_team, object_id: object.id, object_type: 'Repository')
      }

      if can_manage_repository_users?(object)
        urls[:user_roles] = user_roles_access_permissions_repository_path(object)
        urls[:update_access] = access_permissions_repository_path(id: object)
        urls[:new_access] = new_access_permissions_repository_path(id: object.id)
        urls[:create_access] = access_permissions_repositories_path(id: object.id)
        urls[:unassigned_user_groups] = unassigned_user_groups_access_permissions_project_path(id: object.id)
        urls[:user_group_members] = users_users_settings_team_user_groups_path(team_id: object.team.id)
        urls[:show_user_group_assignments_access] = show_user_group_assignments_access_permissions_repository_path(object)
      end

      urls
    end
  end
end
