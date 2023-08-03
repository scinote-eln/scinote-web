# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :load_team, only: :index
      before_action :load_user, only: :show

      def index
        users = timestamps_filter(@team.users).page(params.dig(:page, :number))
                                              .per(params.dig(:page, :size))
        render jsonapi: users, each_serializer: UserSerializer
      end

      def show
        render jsonapi: @user, serializer: UserSerializer
      end

      private

      def load_user
        @user = User.joins(:teams)
                    .where(user_assignments: { assignable: current_user.teams })
                    .find_by(id: params[:id])
        raise PermissionError.new(User, :read) unless @user
      end
    end
  end
end
