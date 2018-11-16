# frozen_string_literal: true

module Api
  module V1
    class ProtocolsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task

      def index
        protocols = @task.protocols
                         .page(params.dig(:page, :number))
                         .per(params.dig(:page, :size))
        render jsonapi: protocols,
          each_serializer: ProtocolSerializer
      end

      private

      def load_protocol
        @protocol = @task.protocols.find(params.require(:id))
      end
    end
  end
end
