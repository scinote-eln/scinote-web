# frozen_string_literal: true

module Dashboard
  class QuickStartController < ApplicationController
    include InputSanitizeHelper

    before_action :load_project, only: %i(create_task experiment_filter)
    before_action :load_experiment, only: :create_task
    before_action :check_task_create_permissions, only: :create_task

    def create_task
      my_module_service = CreateMyModuleService.new(
        current_user, current_team,
        my_module: create_my_module_params,
        project: @project || create_project_params,
        experiment: @experiment || create_experiment_params
      )
      my_module = my_module_service.call
      if my_module_service.errors.blank?
        render json: { my_module_path: protocols_my_module_path(my_module) }
      else
        render json: { errors: my_module_service.errors }, status: :unprocessable_entity
      end
    end

    def project_filter
      projects = Project.readable_by_user(current_user)
                        .search(current_user, false, params[:query], 1, current_team)
                        .select(:id, :name)
                        .order(:name)
                        .map { |i| [i.id, escape_input(i.name)] }
      if (projects.none? { |el| el[1] == params[:query] }) && params[:query].present?
        projects = [[0, params[:query]]] + projects
      end
      render json: { data: projects }
    end

    def experiment_filter
      if @project
        experiments = @project.experiments
                              .managable_by_user(current_user)
                              .search(current_user, false, params[:query], 1, current_team)
                              .order(:name)
                              .select(:id, :name)
        experiments = experiments.map { |i| [i.id, escape_input(i.name)] }
        if (experiments.none? { |el| el[1] == params[:query] }) &&
           params[:query].present? &&
           can_create_project_experiments?(@project)
          experiments = [[0, params[:query]]] + experiments
        end
      elsif params[:query].present?
        experiments = [[0, params[:query]]]
      end
      render json: { data: experiments || [] }
    end

    private

    def create_project_params
      params.require(:project).permit(:name, :visibility, :default_public_user_role_id)
    end

    def create_experiment_params
      params.require(:experiment).permit(:name)
    end

    def create_my_module_params
      params.require(:my_module).permit(:name)
    end

    def load_project
      @project = current_team.projects.readable_by_user(current_user).find_by(id: params.dig(:project, :id))
    end

    def load_experiment
      return unless @project

      @experiment =
        @project.experiments.managable_by_user(current_user).find_by(id: params.dig(:experiment, :id))
    end

    def check_task_create_permissions
      unless @project
        render_403 unless can_create_projects?(current_user, current_team)
        return
      end

      unless @experiment
        render_403 unless can_create_project_experiments?(current_user, @project)
        return
      end

      render_403 unless can_manage_experiment?(current_user, @experiment)
    end
  end
end
