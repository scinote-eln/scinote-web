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
        projects =
          if can_manage_team?(@team)
            # Team owners see all projects in the team
            @team.projects
          else
            @team.projects.readable_by_user(current_user, @team)
          end
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

        project = @team.projects.build(project_params.merge!(created_by: current_user))

        if project.visible? # set default viewer role for public projects
          project.default_public_user_role = UserRole.predefined.find_by(name: I18n.t('user_roles.predefined.viewer'))
        end

        project.save!

        render jsonapi: project, serializer: ProjectSerializer, scope: { metadata: params['with-metadata'] == 'true' }, status: :created
      end

      def update
        @project.assign_attributes(project_params)

        return render body: nil, status: :no_content unless @project.changed?

        if @project.archived_changed?
          if @project.archived?
            @project.archived_by = current_user
          else
            @project.restored_by = current_user
          end
        end
        @project.last_modified_by = current_user
        @project.save!
        render jsonapi: @project, serializer: ProjectSerializer, scope: { metadata: params['with-metadata'] == 'true' }, status: :ok
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
