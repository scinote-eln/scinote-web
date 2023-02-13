# frozen_string_literal: true

module AccessPermissions
  class ProjectsController < ApplicationController
    before_action :set_project
    before_action :check_read_permissions, only: %i(show)
    before_action :check_manage_permissions, except: %i(show)
    before_action :available_users, only: %i(new create)

    def new
      @user_assignment = @project.user_assignments.new(
        assigned_by: current_user,
        team: current_team
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
      @user_assignment = @project.user_assignments.find_by(
        user_id: permitted_update_params[:user_id],
        team: current_team
      )
      @user_assignment.update!(permitted_update_params)

      log_activity(:change_user_role_on_project, @user_assignment)
      propagate_job(user_assignment)

      respond_to do |format|
        format.json do
          render :project_member
        end
      end
    end

    def create
      ActiveRecord::Base.transaction do
        permitted_create_params[:resource_members].each do |_k, user_assignment_params|
          next unless user_assignment_params[:assign] == '1'

          user_assignment = UserAssignment.find_or_initialize_by(
            assignable: @project,
            user_id: user_assignment_params[:user_id],
            team: current_team
          )

          user_assignment.update!(
            user_role_id: user_assignment_params[:user_role_id],
            assigned_by: current_user,
            assigned: :manually
          )

          log_activity(:assign_user_to_project, user_assignment)
          propagate_job(user_assignment)
        end

        respond_to do |format|
          @message = t('access_permissions.create.success', count: @project.user_assignments.count)
          format.json { render :edit }
        end
      rescue ActiveRecord::RecordInvalid
        respond_to do |format|
          @message = t('access_permissions.create.failure')
          format.json { render :new }
        end
      end
    end

    def destroy
      user = @project.assigned_users.find(params[:user_id])
      user_assignment = @project.user_assignments.find_by(user: user, team: current_team)

      if @project.visible?
        user_assignment.update!(
          user_role: @project.default_public_user_role,
          assigned: :automatically
        )
      else
        user_assignment.destroy!
      end

      propagate_job(user_assignment)
      log_activity(:unassign_user_from_project, user_assignment)

      render json: { flash: t('access_permissions.destroy.success', member_name: user.full_name) },
             status: :ok
    rescue ActiveRecord::RecordInvalid
      render json: { flash: t('access_permissions.destroy.failure') },
             status: :unprocessable_entity
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
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id))
    end

    def permitted_create_params
      params.require(:access_permissions_new_user_form)
            .permit(resource_members: %i(assign user_id user_role_id))
    end

    def set_project
      @project = current_team.projects.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @project
    end

    def propagate_job(user_assignment)
      UserAssignments::PropagateAssignmentJob.perform_later(
        @project,
        user_assignment.user,
        user_assignment.user_role,
        current_user
      )
    end

    def check_manage_permissions
      render_403 unless can_manage_project_users?(@project)
    end

    def check_read_permissions
      render_403 unless can_read_project?(@project)
    end

    def available_users
      # automatically assigned or not assigned to project
      @available_users = current_team.users.where(
        id: @project.user_assignments.automatically_assigned.select(:user_id)
      ).or(
        current_team.users.where.not(id: @project.users.select(:id))
      )
    end

    def log_activity(type_of, user_assignment)
      Activities::CreateActivityService
        .call(activity_type: type_of,
              owner: current_user,
              subject: @project,
              team: @project.team,
              project: @project,
              message_items: { project: @project.id,
                               user_target: user_assignment.user.id,
                               role: user_assignment.user_role.name })
    end
  end
end
