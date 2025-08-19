# frozen_string_literal: true

module Lists
  class ProjectAndFolderSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    include Canaid::Helpers::PermissionsHelper
    include CommentHelper
    include AssignmentsHelper

    attributes :name, :code, :created_at, :archived_on, :users, :urls, :folder, :hidden, :completed_experiments, :completed_tasks, :total_tasks,
               :folder_info, :default_public_user_role_id, :team, :top_level_assignable, :supervised_by, :total_experiments,
               :comments, :updated_at, :permissions, :due_date_cell, :start_date_cell, :description, :status, :favorite

    def team
      object.team.name
    end

    def folder
      !project?
    end

    def completed_experiments
      object[:completed_experiments_count]
    end

    def total_experiments
      object[:experiments_count]
    end

    def completed_tasks
      object[:completed_tasks_count]
    end

    def total_tasks
      object[:tasks_count]
    end

    def favorite
      object.favorite if project?
    end

    def top_level_assignable
      project?
    end

    def hidden
      object.hidden? if project?
    end

    def supervised_by
      if project?
        {
          id: object.supervised_by&.id,
          name: object.supervised_by&.name,
          avatar: (avatar_path(object.supervised_by, :icon_small) if object.supervised_by)
        }
      end
    end

    def description
      object.description if project?
    end

    def status
      object.status if project?
    end

    def default_public_user_role_id
      object.default_public_user_role_id if project?
    end

    delegate :code, to: :object

    def created_at
      I18n.l(object.created_at, format: :full_date) if project?
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date) if project?
    end

    def archived_on
      I18n.l(object.archived_on, format: :full) if project? && object.archived_on
    end

    def users
      return unless project?

      prepare_assigned_users
    end

    def comments
      if project?
        @user = scope[:user] || @instance_options[:user]
        {
          count: object.comments.count,
          count_unseen: count_unseen_comments(object, @user)
        }
      end
    end

    def due_date_cell
      if project?
        {
          value: object.due_date,
          value_formatted: (I18n.l(object.due_date, format: :full_date) if object.due_date),
          editable: managable?,
          icon: (if object.one_day_prior? && !object.done?
                   'sn-icon sn-icon-alert-warning text-sn-alert-brittlebush'
                 elsif object.overdue? && !object.done?
                   'sn-icon sn-icon-alert-warning text-sn-delete-red'
                 end)
        }
      end
    end

    def start_date_cell
      if project?
        {
          value: object.start_date,
          value_formatted: (I18n.l(object.start_date, format: :full_date) if object.start_date),
          editable: managable?
        }
      end
    end

    def urls
      urls_list = {
        show: if project?
                experiments_path(project_id: object, view_mode: object.archived ? 'archived' : 'active')
              else
                project_folder_path(object, view_mode: object.archived ? 'archived' : 'active')
              end,
        actions: actions_toolbar_projects_path(items: [{ id: object.id,
                                                         type: project? ? 'projects' : 'project_folders' }].to_json)
      }

      urls_list[:show] = nil if project? && !readable?

      if !project? || managable?
        urls_list[:update] = project? ? project_path(object) : project_folder_path(object)
      end

      if project? && readable?
        urls_list[:favorite] = favorite_project_url(object)
        urls_list[:unfavorite] = unfavorite_project_url(object)
      end

      urls_list[:show_access] = access_permissions_project_path(object)
      urls_list[:show_user_group_assignments_access] = show_user_group_assignments_access_permissions_project_path(object)
      urls_list[:user_group_members] = users_users_settings_team_user_groups_path(team_id: object.team.id)
      urls_list[:user_roles] = user_roles_access_permissions_project_path(object)
      if project? && users_managable?
        urls_list[:assigned_users] = assigned_users_list_project_path(object)
        urls_list[:update_access] = access_permissions_project_path(object)
        urls_list[:new_access] = new_access_permissions_project_path(id: object.id)
        urls_list[:unassigned_user_groups] = unassigned_user_groups_access_permissions_project_path(id: object.id)
        urls_list[:create_access] = access_permissions_projects_path(id: object.id)
      end

      urls_list
    end

    def permissions
      {
        create_comments: project? ? can_create_project_comments?(object) : false,
        manage_users_assignments: project? ? users_managable? : false,
        manage: (project? ? managable? : can_manage_team?(object.team))
      }
    end

    def folder_info
      if folder
        I18n.t('projects.index.folder.description', projects_count: object.projects_count,
folders_count: object.folders_count)
      end
    end

    private

    def project?
      object.instance_of?(Project)
    end

    def readable?
      @readable ||= can_read_project?(object)
    end

    def managable?
      @managable ||= can_manage_project?(object)
    end

    def users_managable?
      @users_managable ||= can_manage_project_users?(object)
    end
  end
end
