# frozen_string_literal: true

module Api
  module V2
    class UserGroupsController < BaseController
      before_action :load_team

      def index
        user_groups = @team.user_groups
                           .page(params.dig(:page, :number))
                           .per(params.dig(:page, :size))
        render jsonapi: user_groups, each_serializer: UserGroupSerializer
      end
    end
  end
end
