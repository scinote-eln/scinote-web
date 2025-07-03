# frozen_string_literal: true

module Lists
  class ProtocolSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    attributes :name, :code, :keywords, :linked_tasks, :nr_of_versions, :assigned_users, :published_by,
               :published_on, :updated_at, :archived_by, :archived_on, :urls,
               :top_level_assignable, :has_draft, :team, :permissions
    attribute :hidden
    attribute :default_public_user_role_id

    def code
      object.parent&.code || object.code
    end

    def hidden
      return object.parent.hidden? if object.parent.present?

      object.hidden?
    end

    def default_public_user_role_id
      object.parent&.default_public_user_role_id || object.default_public_user_role_id
    end

    def keywords
      object.protocol_keywords.map(&:name)
    end

    def team
      object.team.name
    end

    def linked_tasks
      object.nr_of_linked_tasks
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

      user_groups + users
    end

    def has_draft
      if object.in_repository_published_original? || object.in_repository_published_version?
        parent = object.parent || object
        parent.draft.present?
      else
        object.in_repository_draft?
      end
    end

    def published_by
      object.published_by&.full_name
    end

    def published_on
      I18n.l(object.published_on, format: :full) if object.published_on
    end

    def updated_at
      I18n.l(object.updated_at, format: :full) if object.updated_at
    end

    def archived_by
      object.archived_by&.full_name
    end

    def archived_on
      I18n.l(object.archived_on, format: :full) if object.archived_on
    end

    def top_level_assignable
      true
    end

    def permissions
      {
        manage_users_assignments: can_manage_protocol_users?(object)
      }
    end

    def urls
      urls_list = {
        show_access: access_permissions_protocol_path(object),
        versions_list: versions_list_protocol_path(object),
        linked_my_modules: linked_children_protocol_path(object.parent || object),
        versions_modal: versions_modal_protocol_path(object.parent || object),
        show_user_group_assignments_access: show_user_group_assignments_access_permissions_protocol_path(object)
      }

      if can_read_protocol_in_repository?(object)
        urls_list[:show] = if object.in_repository_published_original? && object.latest_published_version.present?
                             protocol_path(object.latest_published_version)
                           else
                             protocol_path(object)
                           end
      end

      if has_draft
        draft = object.initial_draft? ? object : object.draft || object.parent.draft
        urls_list[:show_draft] = protocol_path(draft)
      end

      if can_manage_protocol_users?(object)
        urls_list[:update_access] = access_permissions_protocol_path(object)
        urls_list[:new_access] = new_access_permissions_protocol_path(id: object.id)
        urls_list[:create_access] = access_permissions_protocols_path(id: object.id)
        urls_list[:unassigned_user_groups] = unassigned_user_groups_access_permissions_protocol_path(id: object.id)
        urls_list[:user_group_members] = users_users_settings_team_user_groups_path(team_id: object.team.id)
      end

      urls_list
    end
  end
end
