# frozen_string_literal: true

module Lists
  class ExperimentSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers
    include ApplicationHelper
    include ActionView::Helpers::TextHelper

    attributes :name, :code, :created_at, :updated_at, :workflow_img, :description, :completed_tasks,
               :total_tasks, :archived_on, :urls, :sa_description, :default_public_user_role_id, :team,
               :top_level_assignable, :hidden, :archived, :project_id

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def sa_description
      @user = scope[:user] || @instance_options[:user]
      custom_auto_link(object.description,
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
        show: my_modules_path(experiment_id: object, view_mode: archived ? 'archived' : 'active'),
        actions: actions_toolbar_experiments_path(items: [{ id: object.id }].to_json),
        projects_to_clone: projects_to_clone_experiment_path(object),
        projects_to_move: projects_to_move_experiment_path(object),
        clone: clone_experiment_path(object),
        update: experiment_path(object),
        show_access: access_permissions_experiment_path(object),
        workflow_img: fetch_workflow_img_experiment_path(object)
      }

      if can_manage_project_users?(object.project)
        urls_list[:update_access] = access_permissions_experiment_path(object)
      end
      urls_list
    end

    def workflow_img
      rails_blob_path(object.workflowimg, only_path: true) if object.workflowimg.attached?
    end
  end
end
