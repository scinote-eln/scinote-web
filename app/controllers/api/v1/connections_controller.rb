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
        render jsonapi: @connections, each_serializer: ConnectionSerializer
      end

      def show
        render jsonapi: @connection, serializer: ConnectionSerializer
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        render jsonapi: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_project
        @project = @team.projects.find(params.require(:project_id))
        render jsonapi: {}, status: :forbidden unless can_read_project?(
          @project
        )
      end

      def load_experiment
        @experiment = @project.experiments.find(params.require(:experiment_id))
        render jsonapi: {}, status: :forbidden unless can_read_experiment?(
          @experiment
        )
      end

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
