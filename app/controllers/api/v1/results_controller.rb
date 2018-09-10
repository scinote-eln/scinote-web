# frozen_string_literal: true

module Api
  module V1
    class ResultsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_experiment
      before_action :load_task
      before_action :load_result, only: :show

      def index
        results = @my_module.results
                            .page(params.dig(:page, :number))
                            .per(params.dig(:page, :size))

        render jsonapi: results, include: %w(
          result_table result_text result_asset
        ), each_serializer: ResultSerializer
      end

      def show
        render jsonapi: @result, include: %w(
          result_table result_text result_asset
        ), serializer: ResultSerializer
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

      def load_task
        @my_module = @experiment.my_modules.find(params.require(:task_id))
        render jsonapi: {}, status: :not_found if @my_module.nil?
      end

      def load_result
        @result = @my_module.results.find(
          params.require(:id)
        )
        render jsonapi: {}, status: :not_found if @result.nil?
      end
    end
  end
end
