# frozen_string_literal: true

module Api
  module V1
    class TaskUsersController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :load_user, only: :show

      def index
        users = @task.users
                     .page(params.dig(:page, :number))
                     .per(params.dig(:page, :size))
        render jsonapi: users, each_serializer: UserSerializer
      end

      def show
        render jsonapi: @user, serializer: UserSerializer
      end

      private

      def load_user
        @user = @task.users.find(params.require(:id))
      end
    end
  end
end
