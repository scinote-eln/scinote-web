# frozen_string_literal: true

module Dashboard
  class QuickStartController < ApplicationController
    include InputSanitizeHelper

    before_action :load_project, only: %i(create_task experiment_filter)
    before_action :load_experiment, only: :create_task
    before_action :check_task_create_permissions, only: :create_task

    def create_task
      my_module = CreateMyModuleService.new(current_user, current_team,
                                            my_module: create_my_module_params,
                                            project: @project || create_project_params,
                                            experiment: @experiment || create_experiment_params).call
      if my_module.errors.blank?
        render json: { my_module_path: protocols_my_module_path(my_module) }
      else
        render json: { errors: my_module.errors, error_object: my_module.class.name }, status: :unprocessable_entity
      end
    end

    def project_filter
      projects = Project.readable_by_user(current_user)
                        .search(current_user, false, params[:query], current_team)
                        .page(params[:page] || 1)
                        .per(Constants::SEARCH_LIMIT)
                        .select(:id, :name)
      projects = projects.map { |i| [i.id, escape_input(i.name)] }
      if (projects.map { |i| i[1] }.exclude? params[:query]) && params[:query].present?
        projects = [[0, params[:query]]] + projects
      end
      render json: { data: projects }, status: :ok
    end

    def experiment_filter
      if create_project_params.present? && params[:query].present?
        experiments = [[0, params[:query]]]
      elsif @project
        experiments = @project.experiments
                              .managable_by_user(current_user)
                              .search(current_user, false, params[:query], current_team)
                              .page(params[:page] || 1)
                              .per(Constants::SEARCH_LIMIT)
                              .select(:id, :name)
        experiments = experiments.map { |i| [i.id, escape_input(i.name)] }
        if (experiments.map { |i| i[1] }.exclude? params[:query]) &&
           params[:query].present? &&
           can_create_project_experiments?(@project)
          experiments = [[0, params[:query]]] + experiments
        end
      end
      render json: { data: experiments || [] }, status: :ok
    end

    private

    def create_my_module_params
      params.require(:my_module).permit(:name)
    end

    def create_project_params
      params.require(:project).permit(:name)
    end

    def create_experiment_params
      params.require(:experiment).permit(:name)
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
