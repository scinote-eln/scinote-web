# frozen_string_literal: true

module Api
  module V1
    class ExperimentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action only: :show do
        load_experiment(:id)
      end

      def index
        experiments = @project.experiments
                              .page(params.dig(:page, :number))
                              .per(params.dig(:page, :size))
        render jsonapi: experiments, each_serializer: ExperimentSerializer
      end

      def show
        render jsonapi: @experiment, serializer: ExperimentSerializer
      end
    end
  end
end
