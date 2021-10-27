# frozen_string_literal: true

module Api
  module Service
    class ExperimentsController < BaseController
      before_action :load_team

      def clone
        @project = @team.projects.find(params.require(:clone_experiment).require(:to_project_id))
        raise PermissionError.new(Project, :create_project_experiments) unless can_create_project_experiments?(@project)

        @experiment = Experiment.find(params.require(:clone_experiment).require(:experiment_id))
        raise PermissionError.new(Experiment, :manage) unless can_clone_experiment?(@experiment)

        service = Experiments::CopyExperimentAsTemplateService.call(experiment: @experiment,
                                                                    project: @project,
                                                                    user: current_user)

        if service.succeed?
          render jsonapi: service.cloned_experiment, serializer: Api::V1::ExperimentSerializer
        else
          render json: service.errors, status: :error
        end
      end
    end
  end
end
