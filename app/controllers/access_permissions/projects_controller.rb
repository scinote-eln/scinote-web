# frozen_string_literal: true

module AccessPermissions
  class ProjectsController < ApplicationController
    include InputSanitizeHelper

    before_action :set_project
    before_action :check_read_permissions, only: %i(show)
    before_action :check_manage_permissions, except: %i(show)
    before_action :available_users, only: %i(new create)

    def show
      render json: @project.user_assignments.includes(:user_role, :user).order('users.full_name ASC'),
             each_serializer: UserAssignmentSerializer, user: current_user
    end

    def new
      render json: @available_users, each_serializer: UserSerializer, user: current_user
    end

    def edit; end

    def create
      ActiveRecord::Base.transaction do
        created_count = 0
        if permitted_create_params[:user_id] == 'all'
          @project.update!(visibility: :visible, default_public_user_role_id: permitted_create_params[:user_role_id])
          log_activity(:project_grant_access_to_all_team_members,
                       { visibility: t('projects.activity.visibility_visible'),
                         role: @project.default_public_user_role.name,
                         team: @project.team.id })
        else
          user_assignment = UserAssignment.find_or_initialize_by(
            assignable: @project,
            user_id: permitted_create_params[:user_id],
            team: current_team
          )

          user_assignment.update!(
            user_role_id: permitted_create_params[:user_role_id],
            assigned_by: current_user,
            assigned: :manually
          )

          log_activity(:assign_user_to_project, { user_target: user_assignment.user.id,
                                                  role: user_assignment.user_role.name })
          created_count += 1
          propagate_job(user_assignment)
        end

        @message = if created_count.zero?
                     t('access_permissions.create.success', member_name: t('access_permissions.all_team'))
                   else
                     t('access_permissions.create.success', member_name: escape_input(user_assignment.user.name))
                   end
        render json: { message: @message }
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        errors = @project.errors.present? ? @project.errors&.map(&:message)&.join(',') : e.message
        render json: { flash: errors }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end

    def update
      @user_assignment = @project.user_assignments.find_by(
        user_id: permitted_update_params[:user_id],
        team: current_team
      )

      # prevent role change if it would result in no manually assigned users having the user management permission
      new_user_role = UserRole.find(permitted_update_params[:user_role_id])
      if !new_user_role.has_permission?(ProjectPermissions::USERS_MANAGE) &&
         @user_assignment.last_with_permission?(ProjectPermissions::USERS_MANAGE, assigned: :manually)
        raise ActiveRecord::RecordInvalid
      end

      @user_assignment.update!(permitted_update_params)

      log_activity(:change_user_role_on_project, { user_target: @user_assignment.user.id,
                                                   role: @user_assignment.user_role.name })
      propagate_job(@user_assignment)

      render :project_member
    rescue ActiveRecord::RecordInvalid
      render json: { flash: t('access_permissions.update.failure') }, status: :unprocessable_entity
    end

    def destroy
      user = @project.assigned_users.find(params[:user_id])
      user_assignment = @project.user_assignments.find_by(user: user, team: current_team)

      # prevent deletion of last manually assigned user that can manage users
      if user_assignment.last_with_permission?(ProjectPermissions::USERS_MANAGE, assigned: :manually)
        raise ActiveRecord::RecordInvalid
      end

      UserAssignments::PropagateAssignmentJob.perform_now(
        @project,
        user_assignment.user.id,
        user_assignment.user_role,
        current_user.id,
        destroy: true
      )

      user_assignment.destroy!

      log_activity(:unassign_user_from_project, { user_target: user_assignment.user.id,
                                                  role: user_assignment.user_role.name })

      render json: { message: t('access_permissions.destroy.success', member_name: escape_input(user.full_name)) }
    rescue ActiveRecord::RecordInvalid
      render json: { message: t('access_permissions.destroy.failure') },
             status: :unprocessable_entity
    end

    def update_default_public_user_role
      Project.transaction do
        @project.visibility_will_change!
        @project.last_modified_by = current_user
        if permitted_default_public_user_role_params[:default_public_user_role_id].blank?
          # revoke all team members access
          @project.visibility = :hidden
          previous_user_role_name = @project.default_public_user_role.name
          @project.default_public_user_role_id = nil
          @project.save!
          log_activity(:project_remove_access_from_all_team_members,
                       { visibility: t('projects.activity.visibility_hidden'),
                         role: previous_user_role_name,
                         team: @project.team.id })
          render json: { message: t('access_permissions.update.revoke_all_team_members') }
        else
          # update all team members access
          @project.visibility = :visible
          @project.assign_attributes(permitted_default_public_user_role_params)
          @project.save!
          log_activity(:project_access_changed_all_team_members,
                       { team: @project.team.id, role: @project.default_public_user_role&.name })
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        render json: { flash: @project.errors&.map(&:message)&.join(',') }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end

    private

    def permitted_default_public_user_role_params
      params.require(:object).permit(:default_public_user_role_id)
    end

    def permitted_update_params
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id))
    end

    def permitted_create_params
      params.require(:user_assignment)
            .permit(%i(user_id user_role_id))
    end

    def set_project
      @project = current_team.projects.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @project
    end

    def propagate_job(user_assignment, destroy: false)
      UserAssignments::PropagateAssignmentJob.perform_later(
        @project,
        user_assignment.user.id,
        user_assignment.user_role,
        current_user.id,
        destroy: destroy
      )
    end

    def check_manage_permissions
      render_403 unless can_manage_project_users?(@project)
    end

    def check_read_permissions
      render_403 unless can_read_project_users?(@project)
    end

    def available_users
      # automatically assigned or not assigned to project
      @available_users = current_team.users.where(
        id: @project.user_assignments.automatically_assigned.select(:user_id)
      ).or(
        current_team.users.where.not(id: @project.users.select(:id))
      ).order('users.full_name ASC')
    end

    def log_activity(type_of, message_items = {})
      message_items = { project: @project.id }.merge(message_items)

      Activities::CreateActivityService
        .call(activity_type: type_of,
              owner: current_user,
              subject: @project,
              team: @project.team,
              project: @project,
              message_items: message_items)
    end
  end
end
