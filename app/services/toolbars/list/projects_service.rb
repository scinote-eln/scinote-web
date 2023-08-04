# frozen_string_literal: true

module Toolbars
  module List
    class ProjectsService
      attr_reader :current_user, :current_team, :project_folder_id, :current_view, :current_sort, :archived

      include Canaid::Helpers::PermissionsHelper
      include Rails.application.routes.url_helpers

      def initialize(current_user, params)
        @current_user = current_user
        @current_team = current_user.current_team
        @current_view = params[:view]
        @current_sort = params[:sort]
        @archived = params[:archived]
        @project_folder_id = params[:project_folder_id]
      end

      def as_json
        {
          actions: actions,
          views: %i(table cards),
          view: current_view,
          sorts: %w(archived_new archived_old | new old | atoz ztoa | id_asc id_desc),
          sort: current_sort,
          archived: archived,
          filters: filters
        }
      end

      def actions
        [
          new_project_action,
          new_folder_action
        ].compact
      end

      def filters
        [
          {
            key: 'contains',
            type: 'text',
            label: I18n.t('filters_modal.text.label'),
            placeholder: I18n.t('filters_modal.text.placeholder')
          }
        ]
      end

      private

      def new_project_action
        return unless can_create_projects?(current_team)

        {
          name: 'new',
          label: I18n.t('projects.index.new'),
          icon: 'sn-icon sn-icon-new-task',
          primary: true,
          path: new_project_path(project_folder_id: project_folder_id),
          type: 'remote-modal'
        }
      end

      def new_folder_action
        return unless can_create_project_folders?(current_team)

        {
          name: 'new-folder',
          label: I18n.t('projects.index.new_folder'),
          icon: 'sn-icon sn-icon-folder',
          primary: false,
          path: new_project_folder_path(project_folder_id: project_folder_id),
          type: 'remote-modal'
        }
      end
    end
  end
end
