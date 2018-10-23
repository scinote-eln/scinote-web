# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < BaseController
      before_action :load_team
      before_action :load_project, only: :show
      before_action :load_project_relative, only: :activities

      def index
        projects = @team.projects
                        .page(params.dig(:page, :number))
                        .per(params.dig(:page, :size))

        render jsonapi: projects, each_serializer: ProjectSerializer
      end

      def show
        render jsonapi: @project, serializer: ProjectSerializer
      end

      def activities
        activities = @project.activities
                             .page(params.dig(:page, :number))
                             .per(params.dig(:page, :size))
        render jsonapi: activities,
               each_serializer: ActivitySerializer
      end

      private

      def load_project
        @project = @team.projects.find(params.require(:id))
        permission_error(Project, :read) unless can_read_project?(@project)
      end

      def load_project_relative
        @project = @team.projects.find(params.require(:project_id))
        permission_error(Project, :read) unless can_read_project?(@project)
      end
    end
  end
end
