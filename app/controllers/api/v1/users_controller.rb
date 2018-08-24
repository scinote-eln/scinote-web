# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :load_user, only: :show

      def show
        render jsonapi: @user, serializer: UserSerializer
      end

      private

      def load_user
        @user = User.joins(:user_teams)
                    .where('user_teams.team': current_user.teams)
                    .find_by_id(params[:id])
        render jsonapi: {}, status: :forbidden unless @user
      end
    end
  end
end
