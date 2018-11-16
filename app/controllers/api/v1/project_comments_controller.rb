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
               each_serializer: CommentSerializer,
               hide_project: true
      end

      def show
        render jsonapi: @project_comment,
               serializer: CommentSerializer,
               hide_project: true,
               include: :user
      end

      private

      def load_project_comment
        @project_comment = @project.project_comments.find(params.require(:id))
      end
    end
  end
end
