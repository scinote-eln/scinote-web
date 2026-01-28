# frozen_string_literal: true

module Api
  module V1
    class TeamUsersController < BaseController
      before_action :load_team, only: :index

      def index
        users = timestamps_filter(@team.users).page(params.dig(:page, :number))
                                              .per(params.dig(:page, :size))
        render jsonapi: users, each_serializer: UserSerializer
      end
    end
  end
end
