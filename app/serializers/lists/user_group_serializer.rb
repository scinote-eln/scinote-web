# frozen_string_literal: true

module Lists
  class UserGroupSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    include Canaid::Helpers::PermissionsHelper

    attributes :id, :name, :members, :created_by, :created_at, :updated_at, :urls, :team_users_count, :permissions

    def members
      object.users.map do |u|
        {
          id: u.id,
          avatar: avatar_path(u, :icon_small),
          full_name: u.name
        }
      end
    end

    def team_users_count
      object.team.users.size
    end

    def created_by
      object.created_by.name
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def permissions
      {
        manage: can_manage_team?(object.team)
      }
    end

    def urls
      {
        show: users_settings_team_user_group_path(object.team, object),
        unassigned_users: unassigned_users_users_settings_team_user_groups_path(object.team, user_group_id: object),
        assign_users: users_settings_team_user_group_user_group_memberships_path(object.team, object)
      }
    end
  end
end
