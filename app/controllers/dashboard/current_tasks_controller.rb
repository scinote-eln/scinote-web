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
                MyModule.active.where(projects: { id: @project.id })
              else
                MyModule.active.viewable_by_user(current_user, current_team)
              end

      tasks = tasks.joins(experiment: :project)
                   .where(experiments: { archived: false })
                   .where(projects: { archived: false })

      if task_filters[:mode] == 'assigned'
        tasks = tasks.left_outer_joins(:user_my_modules).where(user_my_modules: { user_id: current_user.id })
      end

      tasks = filter_by_state(tasks)

      case task_filters[:sort]
      when 'start_date'
        tasks = tasks.order('my_modules.started_on': :asc).order('my_modules.name': :asc)
      when 'due_date'
        tasks = tasks.order('my_modules.due_date': :asc).order('my_modules.name': :asc)
      when 'atoz'
        tasks = tasks.order('my_modules.name': :asc)
      when 'ztoa'
        tasks = tasks.order('my_modules.name': :desc)
      else
        tasks
      end

      page = (params[:page] || 1).to_i
      tasks = tasks.search_by_name(current_user, current_team, task_filters[:query])
                   .joins(:my_module_status)
                   .select('my_modules.*', 'my_module_statuses.name as status_name', 'my_module_statuses.color as status_color')
                   .preload(experiment: :project).page(page).per(Constants::INFINITE_SCROLL_LIMIT)

      tasks_list = tasks.map do |task|
        { id: task.id,
          link: protocols_my_module_path(task.id),
          experiment: escape_input(task.experiment.name),
          project: escape_input(task.experiment.project.name),
          name: escape_input(task.name),
          due_date: prepare_due_date(task),
          status_color: task.status_color,
          status_name: task.status_name }
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

    def filter_by_state(tasks)
      tasks.where(my_modules: { state: task_filters[:view] })
    end

    def prepare_due_date(task)
      if task.due_date.present?
        due_date_formatted = I18n.l(task.due_date, format: :full_date)
        if task.is_overdue?
          return { state: 'overdue', text: I18n.t('dashboard.current_tasks.due_date_overdue_html',
                                                  date: due_date_formatted) }
        elsif task.is_one_day_prior?
          return { state: 'day-prior', text: I18n.t('dashboard.current_tasks.due_date_html',
                                                    date: due_date_formatted) }
        end

        return { state: '', text: I18n.t('dashboard.current_tasks.due_date_html', date: due_date_formatted) }
      end
      { state: nil, text: nil }
    end

    def task_filters
      params.permit(:project_id, :experiment_id, :mode, :view, :sort, :query, :page)
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
