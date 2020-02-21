# frozen_string_literal: true

module Dashboard
  class CurrentTasksController < ApplicationController
    include InputSanitizeHelper

    def show
      if params[:project_id]
        if params[:experiment_id]
          tasks = MyModule.active.joins(:experiment).where('experiments.id': params[:experiment_id])
        else
          tasks = MyModule.active.joins(:experiment).where('experiments.project_id': params[:project_id])
        end
      else
        tasks = MyModule.active.joins(experiment: :project).where('projects.team_id': current_team)
      end
      if params[:mode] == 'assigned'
        tasks = tasks.left_outer_joins(:user_my_modules).where('user_my_modules.user_id': current_user.id)
      end
      tasks = tasks.where('my_modules.state': params[:view])

      case params[:sort]
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

      respond_to do |format|
        format.json do
          render json: {
            tasks_list: tasks.map do |task|
              due_date = I18n.l(task.due_date, format: :full_with_comma) if task.due_date.present?
              { id: task.id,
                link: protocols_my_module_path(task.id),
                experiment: task.experiment.name,
                project: task.experiment.project.name,
                name: escape_input(task.name),
                due_date: due_date,
                overdue: task.is_overdue?,
                state: task.state,
                steps_state: task.completed_steps_percentage }
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
      project = current_team.projects.find_by(id: params[:project_id])
      unless project
        render json: []
        return false
      end
      experiments = project.experiments.search(current_user, false, params[:query], 1, current_team).select(:id, :name)
      unless params[:mode] == 'team'
        experiments = experiments.where(id: current_user.my_modules
          .group(:experiment_id).select(:experiment_id).pluck(:experiment_id))
      end
      render json: experiments.map { |i| { value: i.id, label: escape_input(i.name) } }, status: :ok
    end
  end
end
