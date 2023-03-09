# frozen_string_literal: true

module AccessPermissions
  class ProjectsController < ApplicationController
    before_action :set_project
    before_action :check_read_permissions, only: %i(show)
    before_action :check_manage_permissions, except: %i(show)

    def new
      # automatically assigned or not assigned to project
      available_users = current_team.users.where(
        id: @project.user_assignments.automatically_assigned.select(:user_id)
      ).or(
        current_team.users.where.not(id: @project.users.select(:id))
      )

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
      @form = AccessPermissions::EditUserProjectForm.new(current_user, @project)
      @form.update(permitted_update_params)

      respond_to do |format|
        format.json do
          render :project_member
        end
      end
    end

    def create
      @form = AccessPermissions::NewUserProjectForm.new(current_user, @project)
      @form.resource_members = permitted_create_params
      respond_to do |format|
        if @form.save
          @message = t('access_permissions.create.success', count: @form.new_members_count)
          format.json { render :edit }
        else
          @message = t('access_permissions.create.failure')
          format.json { render :new }
        end
      end
    end

    def destroy
      user = @project.users.find(params[:user_id])
      project_member = ProjectMember.new(user, @project, current_user)

      respond_to do |format|
        if project_member.destroy
          format.json do
            render json: { flash: t('access_permissions.destroy.success', member_name: user.full_name) },
                   status: :ok
          end
        else
          format.json do
            render json: { flash: t('access_permissions.destroy.failure') },
                   status: :unprocessable_entity
          end
        end
      end
    end

    def update_default_public_user_role
      @project.update!(permitted_default_public_user_role_params)
      UserAssignments::ProjectGroupAssignmentJob.perform_later(current_team, @project, current_user)
    end

    private

    def permitted_default_public_user_role_params
      params.require(:project).permit(:default_public_user_role_id)
    end

    def permitted_update_params
      params.require(:project_member)
            .permit(%i(user_role_id user_id))
    end

    def permitted_create_params
      params.require(:access_permissions_new_user_project_form)
            .permit(resource_members: %i(assign user_id user_role_id))
    end

    def set_project
      @project = current_team.projects.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @project
    end

    def check_manage_permissions
      render_403 unless can_manage_project_users?(@project)
    end

    def check_read_permissions
      render_403 unless can_read_project?(@project)
    end
  end
end
