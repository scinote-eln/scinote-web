# frozen_string_literal: true

module Lists
  class ExperimentSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers
    include ApplicationHelper
    include ActionView::Helpers::TextHelper

    attributes :name, :code, :created_at, :updated_at, :workflow_img, :description, :completed_tasks,
               :total_tasks, :archived_on, :urls, :sa_description, :default_public_user_role_id, :team, :permissions,
               :top_level_assignable, :hidden, :archived, :project_id, :due_date_cell, :start_date_cell, :status_cell, :favorite

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    # normalize description to handle legacy description newlines
    def description
      return unless object.description

      # if description includes HTML, it is already in the new format.
      return object.description if object.description.match?(/<(.|\n)*?>/)

      simple_format(object.description)
    end

    def sa_description
      @user = scope[:user] || @instance_options[:user]
      custom_auto_link(description,
                       simple_format: false,
                       tags: %w(img),
                       team: object.project.team)
    end

    def default_public_user_role_id
      object.project.default_public_user_role_id
    end

    def hidden
      object.project.hidden?
    end

    def top_level_assignable
      false
    end

    def team
      object.project.team.name
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def archived
      object.archived_branch?
    end

    def archived_on
      I18n.l(object.archived_on || object.project.archived_on, format: :full_date) if archived
    end

    def completed_tasks
      object[:completed_task_count]
    end

    def total_tasks
      object[:task_count]
    end

    def urls
      urls_list = {
        show: my_modules_experiment_path(object, view_mode: archived ? 'archived' : 'active'),
        actions: actions_toolbar_experiments_path(items: [{ id: object.id }].to_json),
        projects_to_clone: projects_to_clone_experiment_path(object),
        projects_to_move: projects_to_move_experiment_path(object),
        clone: clone_experiment_path(object),
        update: experiment_path(object),
        show_access: access_permissions_experiment_path(object),
        show_user_group_assignments_access: show_user_group_assignments_access_permissions_experiment_path(object),
        workflow_img: fetch_workflow_img_experiment_path(object),
        favorite: favorite_experiment_url(object),
        unfavorite: unfavorite_experiment_url(object)
      }

      if can_manage_project_users?(object.project)
        urls_list[:user_roles] = user_roles_access_permissions_experiment_path(object)
        urls_list[:update_access] = access_permissions_experiment_path(object)
        urls_list[:user_group_members] = users_users_settings_team_user_groups_path(team_id: object.team.id)
      end
      urls_list
    end

    def workflow_img
      rails_blob_path(object.workflowimg, only_path: true) if object.workflowimg.attached?
    end

    def status_cell
      {
        status: object.status,
        editable: can_manage_experiment?(object)
      }
    end

    def due_date_cell
      {
        value: due_date,
        value_formatted: due_date,
        editable: can_manage_experiment?(object),
        icon: (if object.one_day_prior? && !object.done?
                 'sn-icon sn-icon-alert-warning text-sn-alert-brittlebush'
               elsif object.overdue? && !object.done?
                 'sn-icon sn-icon-alert-warning text-sn-delete-red'
               end)
      }
    end

    def start_date_cell
      {
        value: start_date,
        value_formatted: start_date,
        editable: can_manage_experiment?(object)
      }
    end

    def permissions
      {
        manage: can_manage_experiment?(object)
      }
    end

    private

    def due_date
      I18n.l(object.due_date, format: :full_date) if object.due_date
    end

    def start_date
      I18n.l(object.start_date, format: :full_date) if object.start_date
    end
  end
end
