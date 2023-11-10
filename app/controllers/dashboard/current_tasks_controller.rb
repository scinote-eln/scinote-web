# frozen_string_literal: true

module Dashboard
  class CurrentTasksController < ApplicationController
    include InputSanitizeHelper
    helper_method :current_task_date

    before_action :load_project, only: %i(show experiment_filter)
    before_action :load_experiment, only: :show
    before_action :check_task_view_permissions, only: :show

    def show
      page = (params[:page] || 1).to_i
      tasks = load_tasks.page(page).per(Constants::INFINITE_SCROLL_LIMIT).without_count

      tasks_list = tasks.map do |task|
        render_to_string(partial: 'dashboards/current_tasks/task', locals: { task: task }, formats: :html)
      end

      render json: { data: tasks_list, next_page: tasks.next_page }
    end

    def project_filter
      projects = current_team.projects
                             .where(archived: false)
                             .viewable_by_user(current_user, current_team)
                             .search_by_name(current_user, current_team, params[:query]).select(:id, :name)

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
      experiments = @project.experiments
                            .where(archived: false)
                            .viewable_by_user(current_user, current_team)
                            .search_by_name(current_user, current_team, params[:query]).select(:id, :name)

      unless params[:mode] == 'team'
        experiments = experiments.where(id: current_user.my_modules
          .group(:experiment_id).select(:experiment_id).pluck(:experiment_id))
      end
      render json: experiments.map { |i| { value: i.id, label: escape_input(i.name) } }, status: :ok
    end

    private

    def current_task_date(task)
      span_class, translation_key, date = nil

      if task.completed?
        translation_key = 'completed_on_html'
        date = task.completed_on
      elsif task.due_date.present?
        date = task.due_date

        if task.is_overdue?
          span_class = 'overdue'
          translation_key = 'due_date_overdue_html'
        elsif task.is_one_day_prior?
          span_class = 'day-prior'
          translation_key = 'due_date_html'
        else
          span_class = ''
          translation_key = 'due_date_html'
        end
      end
      { span_class: span_class, translation_key: translation_key, date: date }
    end

    def task_filters
      params.permit(:project_id, :experiment_id, :mode, :sort, :query, :page, statuses: [])
    end

    def load_project
      @project = current_team.projects.find_by(id: params[:project_id])
    end

    def load_experiment
      @experiment = @project.experiments.find_by(id: params[:experiment_id]) if @project
    end

    def load_tasks
      tasks = if @experiment
                @experiment.my_modules.active
              elsif @project
                MyModule.active.where(projects: { id: @project.id })
              else
                MyModule.active
              end

      tasks = tasks.viewable_by_user(current_user, current_team)

      tasks = tasks.joins(experiment: :project)
                   .where(experiments: { archived: false })
                   .where(projects: { archived: false })

      if task_filters[:mode] == 'assigned'
        tasks = tasks.joins(:user_my_modules).where(user_my_modules: { user_id: current_user.id })
      end

      tasks = tasks.where(my_module_status_id: task_filters[:statuses]) if task_filters[:statuses].present?

      case task_filters[:sort]
      when 'due_first'
        tasks = tasks.order('my_modules.due_date': :asc).order('my_modules.name': :asc)
      when 'due_last'
        tasks = tasks.order('my_modules.due_date': :desc).order('my_modules.name': :asc)
      when 'start_first'
        tasks = tasks.order('my_modules.started_on': :asc).order('my_modules.name': :asc)
      when 'start_last'
        tasks = tasks.order('my_modules.started_on': :desc).order('my_modules.name': :asc)
      when 'atoz'
        tasks = tasks.order('my_modules.name': :asc)
      when 'ztoa'
        tasks = tasks.order('my_modules.name': :desc)
      when 'id_asc'
        tasks = tasks.order('my_modules.id': :asc).order('my_modules.name': :asc)
      when 'id_desc'
        tasks = tasks.order('my_modules.id': :desc).order('my_modules.name': :asc)
      end

      tasks = tasks.search_by_name(current_user, current_team, task_filters[:query]) if task_filters[:query].present?
      tasks.joins(:my_module_status)
           .includes(:my_module_status)
           .select(
             'my_modules.*',
             'my_module_statuses.name AS status_name',
             'my_module_statuses.color AS status_color',
             'projects.name AS project_name',
             'experiments.name AS experiment_name'
           )
    end

    def check_task_view_permissions
      render_403 && return if @project && !can_read_project?(@project)
      render_403 && return if @experiment && !can_read_experiment?(@experiment)
    end
  end
end
