# frozen_string_literal: true

module AccessPermissions
  class ProjectsController < ApplicationController
    before_action :set_project
    before_action :check_read_permissions, only: %i[show]
    before_action :check_manage_permissions, only: %i[new create edit update destroy]

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
      respond_to do |format|
        format.json do
          if @project.update(permitted_update_params)
            head :no_content
          else
            render :edit
          end
        end
      end
    end

    private

    def permitted_update_params
      params.require(:project)
            .permit(user_assignments_attributes: %i[user_role_id _destroy id])
    end

    def set_project
      @project = Project.includes(user_assignments: [:user, :user_role]).find_by(id: params[:id])

      render_404 unless @project
    end

    def check_manage_permissions
      render_403 unless can_manage_project?(@project)
    end

    def check_read_permissions
      render_403 unless can_read_project?(@project)
    end
  end
end
