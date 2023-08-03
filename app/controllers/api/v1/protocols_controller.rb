# frozen_string_literal: true

module Api
  module V1
    class ProtocolsController < BaseController
      include Api::V1::ExtraParams

      before_action :load_team, :load_project, :load_experiment, :load_task
      before_action only: :show do
        load_protocol(:id)
      end

      def index
        protocols = timestamps_filter(@task.protocols).page(params.dig(:page, :number))
                                                      .per(params.dig(:page, :size))
        render jsonapi: protocols,
          each_serializer: ProtocolSerializer, rte_rendering: render_rte?, team: @team
      end

      def show
        render jsonapi: @protocol, serializer: ProtocolSerializer,
                                   include: include_params,
                                   rte_rendering: render_rte?,
                                   team: @team
      end
    end
  end
end
