# frozen_string_literal: true

module Api
  module V1
    class ExperimentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment, only: :show

      def index
        experiments = @project.experiments
                              .page(params.dig(:page, :number))
                              .per(params.dig(:page, :size))
        render jsonapi: experiments, each_serializer: ExperimentSerializer
      end

      def show
        render jsonapi: @experiment, serializer: ExperimentSerializer
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
        @experiment = @project.experiments.find(params.require(:id))
        render jsonapi: {}, status: :forbidden unless can_read_experiment?(
          @experiment
        )
      end
    end
  end
end
