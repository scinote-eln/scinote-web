# frozen_string_literal: true

module Dashboard
  class CurrentTasksController < ApplicationController
    include InputSanitizeHelper

    def show; end

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
