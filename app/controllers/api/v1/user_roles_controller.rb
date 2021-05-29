# frozen_string_literal: true

module Api
  module V1
    class UserRolesController < BaseController
      def index
        user_roles = UserRole.all
                             .page(params.dig(:page, :number))
                             .per(params.dig(:page, :size))
        render jsonapi: user_roles, each_serializer: UserRoleSerializer
      end
    end
  end
end
