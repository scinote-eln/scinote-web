# frozen_string_literal: true

module AccessPermissions
  class ExperimentsController < ApplicationController
    before_action :set_project
    before_action :set_experiment
    before_action :check_read_permissions, only: %i(show)
    before_action :check_manage_permissions, only: %i(edit update)

    def show
      respond_to do |format|
        format.json
      end
    end

    def edit
      respond_to do |format|
        format.json
      end
    end

    def update
      @experiment_member = ExperimentMember.new(current_user, @experiment, @project)
      @experiment_member.update(permitted_update_params)

      respond_to do |format|
        format.json do
          render :experiment_member
        end
      end
    end

    private

    def permitted_update_params
      params.require(:experiment_member)
            .permit(%i(user_role_id user_id))
    end

    def set_project
      @project = current_team.projects.find_by(id: params[:project_id])

      render_404 unless @project
    end

    def set_experiment
      @experiment = @project.experiments.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @experiment
    end

    def check_manage_permissions
      render_403 unless can_manage_experiment_users?(@experiment)
    end

    def check_read_permissions
      render_403 unless can_read_experiment?(@experiment)
    end
  end
end
