# frozen_string_literal: true

module Api
  module V1
    class ProjectCommentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_project_comment, only: :show

      def index
        project_comments = @project.project_comments
                                   .page(params.dig(:page, :number))
                                   .per(params.dig(:page, :size))

        render jsonapi: project_comments,
          each_serializer: ProjectCommentSerializer
      end

      def show
        render jsonapi: @project_comment, serializer: ProjectCommentSerializer
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        render jsonapi: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_project
        @project = @team.projects.find(params.require(:project_id))
        render jsonapi: {}, status: :forbidden unless can_read_project?(
          @project
        )
      end

      def load_project_comment
        @project_comment = @project.project_comments.find(params.require(:id))
        render jsonapi: {}, status: :not_found if @project_comment.nil?
      end
    end
  end
end
