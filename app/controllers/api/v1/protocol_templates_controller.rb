# frozen_string_literal: true

module Api
  module V1
    class ProtocolTemplatesController < BaseController
      include Api::V1::ExtraParams

      before_action :load_team
      before_action only: :show do
        load_protocol_template(:id)
      end

      def index
        protocol_templates = Protocol.latest_available_versions(@team)
                                     .with_granted_permissions(current_user, ProtocolPermissions::READ)
                                     .page(params.dig(:page, :number))
                                     .per(params.dig(:page, :size))

        render jsonapi: protocol_templates,
               each_serializer: ProtocolSerializer, rte_rendering: render_rte?, team: @team
      end

      def show
        render jsonapi: @protocol,
               serializer: ProtocolSerializer,
               include: include_params,
               rte_rendering: render_rte?,
               team: @team
      end

      private

      def load_protocol_template(key = :protocol_id)
        @protocol = @team.protocols.find(params.require(key))
        raise PermissionError.new(Protocol, :read) unless can_read_protocol_in_repository?(@protocol)
      end
    end
  end
end
