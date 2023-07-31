# frozen_string_literal: true

module Api
  module V1
    class ExperimentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action only: :show do
        load_experiment(:id)
      end
      before_action :load_experiment_for_managing, only: %i(update)

      def index
        experiments = timestamps_filter(@project.experiments)
        experiments = archived_filter(experiments).page(params.dig(:page, :number))
                                                  .per(params.dig(:page, :size))
        render jsonapi: experiments, each_serializer: ExperimentSerializer
      end

      def show
        render jsonapi: @experiment, serializer: ExperimentSerializer
      end

      def create
        raise PermissionError.new(Experiment, :create) unless can_create_project_experiments?(@project)

        experiment = @project.experiments.create!(experiment_params.merge!(created_by: current_user,
                                                                           last_modified_by: current_user))

        render jsonapi: experiment, serializer: ExperimentSerializer, status: :created
      end

      def update
        @experiment.assign_attributes(experiment_params)

        return render body: nil, status: :no_content unless @experiment.changed?

        if @experiment.archived_changed?
          if @experiment.archived?
            @experiment.archived_by = current_user
            @experiment.archived_on = DateTime.now
          else
            @experiment.restored_by = current_user
            @experiment.restored_on = DateTime.now
          end
        end
        @experiment.last_modified_by = current_user
        @experiment.save!
        render jsonapi: @experiment, serializer: ExperimentSerializer, status: :ok
      end

      private

      def experiment_params
        raise TypeError unless params.require(:data).require(:type) == 'experiments'

        params.require(:data).require(:attributes).permit(:name, :description, :archived)
      end

      def load_experiment_for_managing
        @experiment = @project.experiments.find(params.require(:id))
        raise PermissionError.new(Experiment, :manage) unless can_manage_experiment?(@experiment)
      end
    end
  end
end
