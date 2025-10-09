# frozen_string_literal: true

class ProjectSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include Canaid::Helpers::PermissionsHelper
  include CommentHelper
  include InputSanitizeHelper

  attributes :name, :code, :created_at, :archived_on, :users, :urls, :hidden, :default_public_user_role_id, :supervised_by,
             :comments, :updated_at, :due_date_cell, :start_date_cell, :description, :status, :permissions

  def hidden
    object.hidden?
  end

  def description
    sanitize_input(object.description)
  end

  def supervised_by
    {
      id: object.supervised_by&.id,
      name: object.supervised_by&.name,
      avatar: (avatar_path(object.supervised_by, :icon_small) if object.supervised_by)
    }
  end

  def created_at
    I18n.l(object.created_at, format: :full_date)
  end

  def updated_at
    I18n.l(object.updated_at, format: :full_date)
  end

  def archived_on
    I18n.l(object.archived_on, format: :full) if object.archived_on
  end

  def users
    object.user_assignments.map do |ua|
      {
        avatar: avatar_path(ua.user, :icon_small),
        full_name: ua.user_name_with_role
      }
    end
  end

  def comments
    @user = scope[:user] || @instance_options[:user]
    {
      count: object.comments.count,
      count_unseen: count_unseen_comments(object, @user)
    }
  end

  def due_date_cell
    {
      value: (I18n.l(object.due_date, format: :default) if object.due_date),
      value_formatted: (I18n.l(object.due_date, format: :full_date) if object.due_date),
      editable: can_manage_project?(@object),
      icon: (if object.one_day_prior? && !object.done?
               'sn-icon sn-icon-alert-warning text-sn-alert-brittlebush'
             elsif object.overdue? && !object.done?
               'sn-icon sn-icon-alert-warning text-sn-delete-red'
             end)
    }
  end

  def start_date_cell
    {
      value: (I18n.l(object.start_date, format: :default) if object.start_date),
      value_formatted: (I18n.l(object.start_date, format: :full_date) if object.start_date),
      editable: can_manage_project?(@object)
    }
  end

  def permissions
    {
      create_comments: can_create_project_comments?(object),
      manage_users_assignments: can_manage_project_users?(object),
      manage: can_manage_project?(object)
    }
  end

  def urls
    urls_list = {}

    urls_list[:favorite] = favorite_project_url(object)
    urls_list[:unfavorite] = unfavorite_project_url(object)
    urls_list[:show_access] = access_permissions_project_path(object)

    urls_list[:update] = project_path(object) if can_manage_project?(object)

    if can_manage_project_users?(object)
      urls_list[:assigned_users] = assigned_users_list_project_path(object)
      urls_list[:update_access] = access_permissions_project_path(object)
      urls_list[:new_access] = new_access_permissions_project_path(id: object.id)
      urls_list[:create_access] = access_permissions_projects_path(id: object.id)
    end

    urls_list
  end
end
