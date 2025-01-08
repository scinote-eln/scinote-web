# frozen_string_literal: true

module Lists
  class FormSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

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
      object.user_assignments.map do |ua|
        {
          avatar: avatar_path(ua.user, :icon_small),
          full_name: ua.user_name_with_role
        }
      end
    end

    def permissions
      {
        manage_users_assignments: can_manage_form_users?(object)
      }
    end

    def urls
      urls_list = {
        show: form_path(object),
        show_access: access_permissions_form_path(object)
      }

      if can_manage_form_users?(object)
        urls_list[:update_access] = access_permissions_form_path(object)
        urls_list[:new_access] = new_access_permissions_form_path(id: object.id)
        urls_list[:create_access] = access_permissions_forms_path(id: object.id)
        urls_list[:default_public_user_role_path] =
          update_default_public_user_role_access_permissions_form_path(object)
      end

      urls_list
    end
  end
end
