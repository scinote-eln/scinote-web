# frozen_string_literal: true

class MyModuleSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :name, :description, :permissions, :description_view, :urls, :last_modified_by_name, :created_at, :updated_at,
             :project_name, :experiment_name, :created_by_name, :is_creator_current_user, :code, :designated_user_ids, :due_date_cell, :start_date_cell, :completed_on

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
      manage_designated_users: can_manage_my_module_designated_users?(object)
    }
  end

  def urls
    {
      show_access: access_permissions_my_module_path(object),
      show_user_group_assignments_access: show_user_group_assignments_access_permissions_my_module_path(object)
    }
  end

  def completed_on
    I18n.l(object.completed_on, format: :full_date) if object.completed_on
  end

  def due_date_cell
    if object.due_date
      {
        value: I18n.l(object.due_date, format: :default),
        value_formatted: I18n.l(object.due_date, format: :full_date)
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
end
