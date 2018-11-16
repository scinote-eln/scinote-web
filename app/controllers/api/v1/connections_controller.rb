# frozen_string_literal: true

module Api
  module V1
    class ConnectionsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_connections
      before_action :load_connection, only: :show

      def index
        @connections = @connections.page(params.dig(:page, :number))
                                   .per(params.dig(:page, :size))
        incl = params[:include] == 'tasks' ? %i(input_task output_task) : nil
        render jsonapi: @connections,
               each_serializer: ConnectionSerializer,
               include: incl
      end

      def show
        render jsonapi: @connection,
               serializer: ConnectionSerializer,
               include: %i(input_task output_task)
      end

      private

      def load_connections
        @connections = Connection.joins(
          'LEFT JOIN my_modules AS inputs ON input_id = inputs.id'
        ).joins(
          'LEFT JOIN my_modules AS outputs ON output_id = outputs.id'
        ).where(
          'inputs.experiment_id = ? OR outputs.experiment_id = ?',
          @experiment.id, @experiment.id
        )
      end

      def load_connection
        @connection = @connections.find(params.require(:id))
      end
    end
  end
end
