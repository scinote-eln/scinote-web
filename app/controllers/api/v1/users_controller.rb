# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :load_user, only: :show
      before_action :check_read_permissions, only: :show

      def show
        render jsonapi: @user, serializer: UserSerializer
      end

      private

      def load_user
        @user = User.find_by(id: params[:id])
        raise PermissionError.new(User, :read) unless @user
      end

      def check_read_permissions
        raise PermissionError.new(User, :read) unless @user.teams.exists?(id: current_user.teams)
      end
    end
  end
end
