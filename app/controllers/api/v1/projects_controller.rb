# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < BaseController
      before_action :load_team
      before_action only: :show do
        load_project(:id)
      end
      before_action :load_project, only: :activities
      before_action :load_project_for_managing, only: %i(update)

      def index
        projects = @team.projects.visible_to(current_user, @team)
        projects = metadata_filter(timestamps_filter(archived_filter(projects)))
                   .page(params.dig(:page, :number))
                   .per(params.dig(:page, :size))

        render jsonapi: projects, each_serializer: ProjectSerializer, scope: { metadata: params['with-metadata'] == 'true' }, include: include_params
      end

      def show
        render jsonapi: @project, serializer: ProjectSerializer, scope: { metadata: params['with-metadata'] == 'true' }, include: include_params
      end

      def create
        raise PermissionError.new(Project, :create) unless can_create_projects?(@team)

        ActiveRecord::Base.transaction do
          project = @team.projects.build(project_params.merge!(created_by: current_user))

          project.save!

          if project_params[:visibility] == 'visible'
            project.team_assignments.create!(
              team: project.team,
              user_role: UserRole.find_predefined_viewer_role,
              assigned_by: current_user,
              assigned: :manually
            )
          end

          render jsonapi: project, serializer: ProjectSerializer, scope: { metadata: params['with-metadata'] == 'true' }, status: :created
        end
      end

      def update
        @project.assign_attributes(project_params)

        return render body: nil, status: :no_content if !@project.changed? && project_params[:visibility].blank?

        ActiveRecord::Base.transaction do
          if @project.archived_changed?
            if @project.archived?
              @project.archived_by = current_user
            else
              @project.restored_by = current_user
            end
          end
          @project.last_modified_by = current_user
          @project.save!

          if project_params[:visibility].present?
            team_assignment = @project.team_assignments.find_by(team: @team)

            if project_params[:visibility] == 'hidden' && team_assignment.present?
              team_assignment.destroy!
            elsif project_params[:visibility] == 'visible' && team_assignment.blank?
              @project.team_assignments.create!(
                team: @project.team,
                user_role: UserRole.find_predefined_viewer_role,
                assigned_by: current_user,
                assigned: :manually
              )
            end
          end

          render jsonapi: @project, serializer: ProjectSerializer, scope: { metadata: params['with-metadata'] == 'true' }, status: :ok
        end
      end

      def activities
        activities = @project.activities
                             .page(params.dig(:page, :number))
                             .per(params.dig(:page, :size))
        render jsonapi: activities,
               each_serializer: ActivitySerializer
      end

      private

      def project_params
        raise TypeError unless params.require(:data).require(:type) == 'projects'

        params.require(:data)
              .require(:attributes)
              .permit(:name, :visibility, :supervised_by_id, :archived, :project_folder_id, :start_date, :due_date, :status, :description, metadata: {})
      end

      def permitted_includes
        %w(comments supervised_by)
      end

      def load_project_for_managing
        @project = @team.projects.find(params.require(:id))
        raise PermissionError.new(Project, :manage) unless can_manage_project?(@project)
      end
    end
  end
end
