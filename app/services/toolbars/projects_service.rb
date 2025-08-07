# frozen_string_literal: true

module Toolbars
  class ProjectsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(projects, project_folders, current_user)
      @current_user = current_user
      @projects = projects
      @project_folders = project_folders
      @items = @projects + @project_folders
      @single = @items.length == 1

      @item_type = if projects.blank? && project_folders.blank?
                     :none
                   elsif projects.present? && project_folders.present?
                     :any
                   elsif project_folders.present?
                     :project_folder
                   else
                     :project
                   end
    end

    def actions
      return [] if @item_type == :none

      [
        restore_action,
        edit_action,
        access_action,
        move_action,
        export_action,
        archive_action,
        comments_action,
        activities_action,
        delete_folder_action
      ].compact
    end

    private

    def edit_action
      return unless @single

      action = {
        name: 'edit',
        label: I18n.t('projects.index.edit_option'),
        icon: 'sn-icon sn-icon-edit',
        button_class: 'edit-btn',
        type: :emit
      }

      if @items.first.is_a?(Project)
        return unless can_manage_project?(@items.first)
      else
        return unless can_create_project_folders?(@items.first.team)
      end

      action
    end

    def access_action
      return unless @single

      return unless @item_type == :project

      project = @items.first

      return unless can_manage_team?(project.team) || can_read_project?(project)

      {
        name: 'access',
        label: I18n.t('general.access'),
        icon: 'sn-icon sn-icon-project-member-access',
        type: :emit
      }
    end

    def move_action
      return unless can_manage_team?(@items.first.team) &&
                    @items.all? { |item| item.is_a?(Project) ? can_read_project?(item) : true }

      {
        name: 'move',
        label: I18n.t('projects.index.move_button'),
        icon: 'sn-icon sn-icon-move',
        path: move_to_modal_project_folders_path,
        type: :emit
      }
    end

    def export_action
      return unless @items.all? { |item| item.is_a?(Project) ? can_export_project?(item) : true }

      num_projects = count_of_export_projects
      limit = TeamZipExport.exports_limit
      num_of_requests_left = @current_user.exports_left - 1
      team = @items.first.team

      message = if limit.zero? || num_of_requests_left.positive?
                  "<p>#{I18n.t('projects.export_projects.modal_text_p1_html',
                               num_projects: num_projects,
                               team: team.name)}</p>
                   <p>#{I18n.t('projects.export_projects.modal_text_p2_html')}</p>"
                else
                  "<p>#{I18n.t('repositories.index.modal_export_limit_exceeded.error_p1_html', limit: limit)}</p>
                   <p>#{I18n.t('repositories.index.modal_export_limit_exceeded.error_p2_html', limit: limit)}</p>"
                end
      unless limit.zero? || !num_of_requests_left.positive?
        message += "<p><i>#{I18n.t('projects.export_projects.modal_text_p3_html', limit: limit, num: num_of_requests_left)}</i></p>"
      end

      {
        items: @items,
        name: 'export',
        label: I18n.t('projects.export_projects.export_button'),
        icon: 'sn-icon sn-icon-export',
        message: message,
        number_of_request_left: limit.zero? ? 1 : num_of_requests_left,
        path: export_projects_team_path(team),
        number_of_projects: num_projects,
        type: :emit
      }
    end

    def archive_action
      return unless @items.all? do |item|
        item.is_a?(Project) && can_archive_project?(item)
      end

      {
        name: 'archive',
        label: I18n.t('projects.index.archive_button'),
        icon: 'sn-icon sn-icon-archive',
        path: archive_group_projects_path,
        type: :emit,
      }
    end

    def restore_action
      return unless @items.all? do |item|
        item.is_a?(Project) && can_restore_project?(item)
      end

      {
        name: 'restore',
        label: I18n.t('projects.index.restore_button'),
        icon: 'sn-icon sn-icon-restore',
        button_class: 'restore-projects-btn',
        path: restore_group_projects_path,
        type: :emit
      }
    end

    def delete_folder_action
      return unless @items.all? do |item|
        item.is_a?(ProjectFolder) && can_delete_project_folder?(item)
      end

      {
        name: 'delete_folders',
        label: I18n.t('general.delete'),
        icon: 'sn-icon sn-icon-delete',
        path: destroy_project_folders_path,
        type: :emit
      }
    end

    def comments_action
      return unless @single

      return unless @item_type == :project

      project = @items.first

      return unless can_read_project?(project)

      {
        name: 'comments',
        label: I18n.t('Comments'),
        icon: 'sn-icon sn-icon-comments',
        type: :emit
      }
    end

    def activities_action
      return unless @single

      return unless @item_type == :project

      project = @items.first

      return unless can_read_project?(project)

      activity_url_params = Activity.url_search_query({ subjects: { Project: [project] } })

      {
        name: 'activities',
        label: I18n.t('nav.label.activities'),
        icon: 'sn-icon sn-icon-activities',
        button_class: 'project-activities-btn',
        path: "/global_activities?#{activity_url_params}",
        type: :link
      }
    end

    def count_of_export_projects
      @items.sum do |item|
        if item.is_a?(Project) && can_export_project?(item)
          1
        elsif item.respond_to?(:inner_projects)
          item.inner_projects.readable_by_user(@current_user, item.team).count do |project|
            can_export_project?(project)
          end
        else
          0
        end
      end
    end
  end
end
