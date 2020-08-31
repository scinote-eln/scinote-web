# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < BaseController
      before_action :load_team
      before_action only: :show do
        load_project(:id)
      end
      before_action :load_project, only: :activities

      def index
        projects = @team.projects
                        .visible_to(current_user, @team)
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
    end
  end
end
