# frozen_string_literal: true

module Api
  module V1
    class ProtocolsController < BaseController
      include Api::V1::ExtraParams

      before_action :load_team, :load_project, :load_experiment, :load_task
      before_action only: %i(show update) do
        load_protocol(:id)
      end
      before_action :check_manage_permissions, only: :update

      def index
        protocols = timestamps_filter(@task.protocols).page(params.dig(:page, :number))
                                                      .per(params.dig(:page, :size))
        render jsonapi: protocols, each_serializer: ProtocolSerializer, rte_rendering: render_rte?, team: @team
      end

      def show
        render jsonapi: @protocol, serializer: ProtocolSerializer,
                                   include: include_params,
                                   rte_rendering: render_rte?,
                                   team: @team
      end

      def update
        @protocol.assign_attributes(protocol_params)

        if @protocol.changed? && @protocol.save!
          render jsonapi: @protocol, serializer: ProtocolSerializer, status: :ok
        else
          render status: :no_content
        end
      end

      private

      def protocol_params
        raise TypeError unless params.require(:data).require(:type) == 'protocols'

        params.require(:data).require(:attributes).permit(:name, :description)
      end

      def check_manage_permissions
        raise PermissionError.new(Protocol, :manage) unless can_manage_my_module_protocol?(@task)
      end
    end
  end
end
