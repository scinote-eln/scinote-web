# frozen_string_literal: true

module Lists
  class FormSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers
    include AssignmentsHelper

    attributes :id, :name, :published_on, :published_by, :updated_at, :urls, :code, :top_level_assignable, :hidden,
               :team, :default_public_user_role_id, :permissions, :assigned_users, :versions, :used_in_protocols

    def published_by
      object.published_by&.full_name
    end

    def published_on
      I18n.l(object.published_on, format: :full) if object.published_on
    end

    def updated_at
      I18n.l(object.updated_at, format: :full) if object.updated_at
    end

    def top_level_assignable
      true
    end

    def hidden
      object.hidden?
    end

    def used_in_protocols
      object.form_responses.count
    end

    def versions
      I18n.t("forms.#{object.published? ? 'published' : 'draft'}")
    end

    def team
      object.team.name
    end

    def assigned_users
      prepare_assigned_users
    end

    def permissions
      {
        manage_users_assignments: can_manage_form_users?(object)
      }
    end

    def urls
      urls_list = {
        show_access: access_permissions_form_path(object),
        show_user_group_assignments_access: show_user_group_assignments_access_permissions_form_path(object),
        user_roles: user_roles_access_permissions_form_path(object)
      }

      urls_list[:show] = form_path(object) if can_read_form?(object)

      if can_manage_form_users?(object)
        urls_list[:update_access] = access_permissions_form_path(object)
        urls_list[:new_access] = new_access_permissions_form_path(id: object.id)
        urls_list[:create_access] = access_permissions_forms_path(id: object.id)
        urls_list[:unassigned_user_groups] = unassigned_user_groups_access_permissions_form_path(id: object.id)
        urls_list[:user_group_members] = users_users_settings_team_user_groups_path(team_id: object.team.id)
      end

      urls_list
    end
  end
end
