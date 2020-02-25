# frozen_string_literal: true

module Dashboard
  class QuickStartController < ApplicationController
    before_action :load_project, only: :create_task
    before_action :load_experiment, only: :create_task
    before_action :check_task_create_permissions, only: :create_task

    def create_task
      my_module = CreateMyModuleService.new(current_user, current_team,
                                            project: @project || create_project_params,
                                            experiment: @experiment || create_experiment_params).call
      if my_module
        render json: { my_module_path: protocols_my_module_path(my_module) }
      else
        render json: {}, status: :unprocessable_entity
      end
    end

    private

    def create_project_params
      params.require(:project).permit(:name)
    end

    def create_experiment_params
      params.require(:experiment).permit(:name)
    end

    def load_project
      @project = current_team.projects.find_by(id: params.dig(:project, :id))
    end

    def load_experiment
      @experiment = @project.experiments.find_by(id: params.dig(:experiment, :id)) if @project
    end

    def check_task_create_permissions
      unless @project
        render_403 unless can_create_projects?(current_user, current_team)
        return
      end

      unless @experiment
        render_403 unless can_create_experiments?(current_user, @project)
        return
      end

      render_403 unless can_manage_experiment?(current_user, @experiment)
    end
  end
end
