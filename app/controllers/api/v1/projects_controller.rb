# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < BaseController
      before_action :load_team
      before_action :load_project, only: :show

      def index
        projects = @team.projects
                        .page(params.dig(:page, :number))
                        .per(params.dig(:page, :size))

        render jsonapi: projects, each_serializer: ProjectSerializer
      end

      def show
        render jsonapi: @project, serializer: ProjectSerializer
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        render jsonapi: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_project
        @project = @team.projects.find(params.require(:id))
        render jsonapi: {}, status: :forbidden unless can_read_project?(
          @project
        )
      end
    end
  end
end
