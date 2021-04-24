# frozen_string_literal: true

module AccessPermissions
  class ProjectsController < ApplicationController
    before_action :set_project
    before_action :check_read_permissions, only: %i[show]
    before_action :check_manage_permissions, only: %i[new create edit update destroy]

    def new
      available_users = current_team.users.where.not(id: @project.users.pluck(:id))
      @form = AccessPermissions::NewUserProjectForm.new(
        current_user,
        @project,
        users: available_users
      )

      respond_to do |format|
        format.json
      end
    end

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

    def create
      @form = AccessPermissions::NewUserProjectForm.new(current_user, @project)
      @form.resource_members = permitted_create_params

      flash[:notice] = "Success" if @form.save

      respond_to do |format|
        format.json :new
      end
    end

    private

    def permitted_update_params
      params.require(:project)
            .permit(user_assignments_attributes: %i[user_role_id _destroy id])
    end

    def permitted_create_params
      params.require(:access_permissions_new_user_project_form)
            .permit(resource_members: %i[assign user_id user_role_id])
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
