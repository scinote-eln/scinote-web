# frozen_string_literal: true

class MyModuleSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :name, :description, :permissions, :description_view, :urls, :last_modified_by_name, :created_at, :updated_at, :tags, :updated_at_unix, :tags_html,
             :project_name, :experiment_name, :created_by_name, :is_creator_current_user, :code, :designated_user_ids, :due_date_cell, :start_date_cell, :completed_on,
             :default_public_user_role_id, :team

  def team
    object.team.name
  end

  def project_name
    object.experiment.project.name
  end

  def experiment_name
    object.experiment.name
  end

  def created_by_name
    object.created_by&.full_name
  end

  def is_creator_current_user
    object.created_by == scope[:user]
  end

  def created_at
    I18n.l(object.created_at, format: :full_date)
  end

  def updated_at
    I18n.l(object.updated_at, format: :full_date)
  end

  def updated_at_unix
    object.updated_at.to_i
  end

  def last_modified_by_name
    object.last_modified_by&.full_name
  end

  def designated_user_ids
    object.designated_users.pluck(:id)
  end

  def permissions
    {
      manage_description: can_update_my_module_description?(object),
      manage_due_date: can_update_my_module_due_date?(object),
      manage_start_date: can_update_my_module_start_date?(object),
      manage_designated_users: can_manage_my_module_designated_users?(object),
      assign_tags: can_manage_my_module_tags?(object)
    }
  end

  def urls
    urls_list = {
      show_access: access_permissions_my_module_path(object),
      show_user_group_assignments_access: show_user_group_assignments_access_permissions_my_module_path(object),
      tag_resource: tag_resource_my_module_path(object),
      untag_resource: untag_resource_my_module_path(object),
      tag_resource_with_new_tag: tag_resource_with_new_tag_my_module_path(object),
      user_roles: user_roles_access_permissions_my_module_path(object),
      user_group_members: users_users_settings_team_user_groups_path(team_id: object.team.id)
    }

    urls_list[:update_access] = access_permissions_my_module_path(object) if can_manage_my_module_users?(object)

    urls_list
  end

  def completed_on
    I18n.l(object.completed_on, format: :full_date) if object.completed_on
  end

  def due_date_cell
    if object.due_date
      {
        value: I18n.l(object.due_date, format: :default),
        value_formatted: I18n.l(object.due_date, format: :full_date),
        icon: (if object.is_one_day_prior? && !object.completed?
                 'sn-icon sn-icon-alert-warning text-sn-alert-brittlebush'
               elsif object.is_overdue? && !object.completed?
                 'sn-icon sn-icon-alert-warning text-sn-delete-red'
               end)
      }
    else
      {
        value: nil,
        value_formatted: nil
      }
    end
  end

  def start_date_cell
    if object.started_on
      {
        value: I18n.l(object.started_on, format: :default),
        value_formatted: I18n.l(object.started_on, format: :full_date)
      }
    else
      {
        value: nil,
        value_formatted: nil
      }
    end
  end

  def description_view
    @user = scope[:user]
    custom_auto_link(object.tinymce_render('description'),
                     simple_format: false,
                     tags: %w(img),
                     team: object.team)
  end

  def description
    sanitize_input(object.tinymce_render('description'))
  end

  def tags
    object.tags.map do |tag|
      { id: tag.id, name: tag.name, color: tag.color }
    end
  end

  def tags_html
    # legacy canvas support
    return '' unless @instance_options[:controller]

    @instance_options[:controller].render_to_string(
      partial: 'canvas/tags',
      locals: { my_module: object },
      formats: :html
    )
  end
end
