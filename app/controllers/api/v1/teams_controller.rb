# frozen_string_literal: true

module Api
  module V1
    class TeamsController < BaseController
      before_action only: :show do
        load_team(:id)
      end

      def index
        teams = timestamps_filter(current_user.teams).page(params.dig(:page, :number))
                                                     .per(params.dig(:page, :size))
        render jsonapi: teams, each_serializer: TeamSerializer
      end

      def show
        render jsonapi: @team, serializer: TeamSerializer, include: :created_by
      end
    end
  end
end
