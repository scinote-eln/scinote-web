# frozen_string_literal: true

module Dashboard
  class CurrentTasksController < ApplicationController
    include InputSanitizeHelper

    before_action :load_project, only: %i(show experiment_filter)
    before_action :load_experiment, only: :show
    before_action :check_task_view_permissions, only: :show

    def show
      tasks = if @experiment
                @experiment.my_modules.active
              elsif @project
                MyModule.active.joins(:experiment).where('experiments.project_id': @project.id)
              else
                MyModule.active.viewable_by_user(current_user, current_team)
              end
      if task_filters[:mode] == 'assigned'
        tasks = tasks.left_outer_joins(:user_my_modules).where('user_my_modules.user_id': current_user.id)
      end
      tasks = tasks.where('my_modules.state': task_filters[:view])
                   .search_by_name(current_user, current_team, task_filters[:query])

      case task_filters[:sort]
      when 'date_desc'
        tasks = tasks.order('my_modules.due_date': :desc)
      when 'date_asc'
        tasks = tasks.order('my_modules.due_date': :asc)
      when 'atoz'
        tasks = tasks.order('my_modules.name': :asc)
      when 'ztoa'
        tasks = tasks.order('my_modules.name': :desc)
      else
        tasks
      end

      tasks = tasks.with_step_statistics.preload(experiment: :project)

      respond_to do |format|
        format.json do
          render json: {
            tasks_list: tasks.map do |task|
              { id: task.id,
                link: protocols_my_module_path(task.id),
                experiment: escape_input(task.experiment.name),
                project: escape_input(task.experiment.project.name),
                name: escape_input(task.name),
                due_date: task.due_date.present? ? I18n.l(task.due_date, format: :full_date) : nil,
                overdue: task.is_overdue?,
                state: task.state,
                steps_state: { completed_steps: task.steps_completed,
                               all_steps: task.steps_total,
                               percentage: task.steps_completed_percentage } }
            end,
            status: :ok
          }
        end
      end
    end

    def project_filter
      projects = current_team.projects.search(current_user, false, params[:query], 1, current_team).select(:id, :name)
      unless params[:mode] == 'team'
        projects = projects.where(id: current_user.my_modules.joins(:experiment)
          .group(:project_id).select(:project_id).pluck(:project_id))
      end
      render json: projects.map { |i| { value: i.id, label: escape_input(i.name) } }, status: :ok
    end

    def experiment_filter
      unless @project
        render json: []
        return false
      end
      experiments = @project.experiments.search(current_user, false, params[:query], 1, current_team).select(:id, :name)
      unless params[:mode] == 'team'
        experiments = experiments.where(id: current_user.my_modules
          .group(:experiment_id).select(:experiment_id).pluck(:experiment_id))
      end
      render json: experiments.map { |i| { value: i.id, label: escape_input(i.name) } }, status: :ok
    end

    private

    def task_filters
      params.permit(:project_id, :experiment_id, :mode, :view, :sort, :query)
    end

    def load_project
      @project = current_team.projects.find_by(id: params[:project_id])
    end

    def load_experiment
      @experiment = @project.experiments.find_by(id: params[:experiment_id]) if @project
    end

    def check_task_view_permissions
      render_403 if @project && !can_read_project?(@project)
      render_403 if @experiment && !can_read_experiment?(@experiment)
    end
  end
end
