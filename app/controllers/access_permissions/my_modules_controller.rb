# frozen_string_literal: true

module AccessPermissions
  class MyModulesController < ApplicationController
    before_action :set_project
    before_action :set_experiment
    before_action :set_my_module
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
      @my_module_member = MyModuleMember.new(current_user, @my_module, @experiment, @project)

      if permitted_update_params[:user_role_id] == 'reset'
        @my_module_member.reset(permitted_update_params)
      else
        @my_module_member.update(permitted_update_params)
      end

      respond_to do |format|
        format.json do
          render :my_module_member
        end
      end
    end

    private

    def permitted_update_params
      params.require(:my_module_member)
            .permit(%i(user_role_id user_id))
    end

    def set_project
      @project = current_team.projects.find_by(id: params[:project_id])

      render_404 unless @project
    end

    def set_experiment
      @experiment = @project.experiments.find_by(id: params[:experiment_id])

      render_404 unless @experiment
    end

    def set_my_module
      @my_module = @experiment.my_modules.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @my_module
    end

    def check_manage_permissions
      render_403 unless can_manage_my_module_users?(@my_module)
    end

    def check_read_permissions
      render_403 unless can_read_my_module?(@my_module)
    end
  end
end
