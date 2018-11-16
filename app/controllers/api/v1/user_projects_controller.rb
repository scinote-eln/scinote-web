# frozen_string_literal: true

module Api
  module V1
    class UserProjectsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_user_project, only: :show

      def index
        user_projects = @project.user_projects
                                .page(params.dig(:page, :number))
                                .per(params.dig(:page, :size))

        render jsonapi: user_projects,
               each_serializer: UserProjectSerializer,
               include: :user
      end

      def show
        render jsonapi: @user_project,
               serializer: UserProjectSerializer,
               include: :user
      end

      private

      def load_user_project
        @user_project = @project.user_projects.find(params.require(:id))
      end
    end
  end
end
