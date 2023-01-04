# frozen_string_literal: true

module Api
  module V1
    class ConnectionsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_connections
      before_action :load_connection, only: %i(show destroy)
      before_action :check_manage_permissions, except: %i(index show destroy)

      def index
        @connections = @connections.page(params.dig(:page, :number))
                                   .per(params.dig(:page, :size))
        render jsonapi: @connections,
               each_serializer: ConnectionSerializer,
               include: include_params
      end

      def show
        render jsonapi: @connection,
               serializer: ConnectionSerializer,
               include: include_params
      end

      def create
        connection = Connection.create!(connection_params)

        render jsonapi: connection,
               serializer: ConnectionSerializer,
               include: include_params
      end

      def destroy
        raise PermissionError.new(Connection, :destroy) unless can_manage_experiment?(@experiment)

        @connection.destroy!
        render body: nil
      end

      private

      def load_connections
        @connections = @experiment.connections
      end

      def load_connection
        @connection = @connections.find(params.require(:id))
      end

      def connection_params
        raise TypeError unless params.require(:data).require(:type) == 'connections'

        params.require(:data).require(:attributes).permit(:input_id, :output_id)
      end

      def check_manage_permissions
        input_output_ids = [connection_params[:input_id], connection_params[:output_id]]

        unless can_manage_experiment?(@experiment) && (input_output_ids - @experiment.my_modules.pluck(:id)).empty?
          raise PermissionError.new(Connection, :create)
        end
      end

      def permitted_includes
        %w(to from)
      end
    end
  end
end
