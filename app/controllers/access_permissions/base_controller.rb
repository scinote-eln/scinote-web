# frozen_string_literal: true

module AccessPermissions
  class BaseController < ApplicationController
    include InputSanitizeHelper

    before_action :set_model
    before_action :set_assignment, only: %i(create update destroy)
    before_action :check_read_permissions, only: %i(show show_user_group_assignments)
    before_action :check_manage_permissions, except: %i(show show_user_group_assignments)
    before_action :available_users, only: %i(new create)

    def show
      render json: @model.user_assignments.includes(:user_role, :user).order('users.full_name ASC'),
             each_serializer: UserAssignmentSerializer, user: current_user
    end

    def new
      render json: @available_users, each_serializer: UserSerializer, user: current_user
    end

    def edit; end

    def create
      ActiveRecord::Base.transaction do
        created_count = 0
        if permitted_params[:user_id] == 'all'
          @model.update!(visibility: :visible, default_public_user_role_id: permitted_params[:user_role_id])
          log_activity(:"#{model_parameter}_grant_access_to_all_team_members",
                       { visibility: t('projects.activity.visibility_visible'),
                         role: @model.default_public_user_role.name,
                         team: @model.team.id })
        else
          @assignment.update!(
            user_role_id: permitted_params[:user_role_id],
            assigned_by: current_user,
            assigned: :manually
          )

          if permitted_params[:user_id].present?
            log_activity(:"#{model_parameter}_access_granted", user_target: @assignment.user.id, role: @assignment.user_role.name)
          else
            log_activity(:"#{model_parameter}_access_granted_user_group", user_group: @assignment.user_group.id, role: @assignment.user_role.name)
          end

          created_count += 1

          propagate_job
        end

        @message = if created_count.zero?
                     t('access_permissions.create.success', member_name: t('access_permissions.all_team'))
                   else
                     t('access_permissions.create.success', member_name: escape_input(@assignment.respond_to?(:user_group) ? @assignment.user_group.name : @assignment.user.name))
                   end
        render json: { message: @message }
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        errors = @model.errors.present? ? @model.errors&.map(&:message)&.join(',') : e.message
        render json: { flash: errors }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end

    def update
      # prevent role change if it would result in no manually assigned users having the user management permission
      new_user_role = UserRole.find(permitted_params[:user_role_id])
      if permitted_params[:user_id].present? && !new_user_role.has_permission?(manage_permission_constant) &&
         @assignment.last_with_permission?(manage_permission_constant, assigned: :manually)
        raise ActiveRecord::RecordInvalid
      end

      @assignment.update!(permitted_params)
      if permitted_params[:user_id].present?
        log_activity(:"#{model_parameter}_access_changed", user_target: @assignment.user.id, role: @assignment.user_role.name)
      else
        log_activity(:"#{model_parameter}_access_changed_user_group", user_group: @assignment.user_group.id, role: @assignment.user_role.name)
      end

      propagate_job
    rescue ActiveRecord::RecordInvalid
      render json: { flash: t('access_permissions.update.failure') }, status: :unprocessable_entity
    end

    def destroy
      # prevent deletion of last manually assigned user that can manage users
      raise ActiveRecord::RecordInvalid if params[:user_id].present? && @assignment.last_with_permission?(manage_permission_constant, assigned: :manually)

      is_group = @assignment.respond_to?(:user_group)

      UserAssignments::PropagateAssignmentJob.perform_now(
        @model,
        is_group ? @assignment.user_group.id : @assignment.user.id,
        @assignment.user_role,
        current_user.id,
        team_id: current_team.id,
        group: is_group,
        destroy: true
      )

      if is_group
        log_activity(:"#{model_parameter}_access_revoked_user_group", user_group: @assignment.user_group.id, role: @assignment.user_role.name)
      else
        log_activity(:"#{model_parameter}_access_revoked", user_target: @assignment.user.id, role: @assignment.user_role.name)
      end

      render json: { message: t('access_permissions.destroy.success', member_name: escape_input(is_group ? @assignment.user_group.name : @assignment.user.full_name)) }
    rescue ActiveRecord::RecordInvalid
      render json: { message: t('access_permissions.destroy.failure') },
             status: :unprocessable_entity
    end

    def show_user_group_assignments
      render json: @model.user_group_assignments.includes(:user_role, :user_group).order('user_groups.name ASC'),
             each_serializer: UserGroupAssignmentSerializer, user: current_user
    end

    def unassigned_user_groups
      render json: current_team.user_groups.where.not(id: @model.user_group_assignments.select(:user_group_id)),
             each_serializer: UserGroupSerializer, user: current_user
    end

    def update_default_public_user_role
      ActiveRecord::Base.transaction do
        @model.visibility_will_change!
        @model.last_modified_by = current_user
        if permitted_default_public_user_role_params[:default_public_user_role_id].blank?
          # revoke all team members access
          @model.visibility = :hidden
          previous_user_role_name = @model.default_public_user_role.name
          @model.default_public_user_role_id = nil
          @model.save!
          log_activity(:"#{model_parameter}_remove_access_from_all_team_members",
                       { visibility: t('projects.activity.visibility_hidden'),
                         role: previous_user_role_name,
                         team: @model.team.id })
          render json: { message: t('access_permissions.update.revoke_all_team_members') }
        else
          # update all team members access
          @model.visibility = :visible
          @model.assign_attributes(permitted_default_public_user_role_params)
          @model.save!
          log_activity(:"#{model_parameter}_access_changed_all_team_members",
                       { team: @model.team.id, role: @model.default_public_user_role&.name })
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        render json: { flash: @model.errors&.map(&:message)&.join(',') }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end

    private

    def model_parameter
      @model.class.name.parameterize.to_sym
    end

    def manage_permission_constant
      "#{@model.class.name}Permissions::USERS_MANAGE".constantize
    end

    def permitted_default_public_user_role_params
      params.require(:object).permit(:default_public_user_role_id)
    end

    def permitted_params
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id user_group_id team_id))
    end

    def available_users
      # automatically assigned or not assigned to project
      @available_users = current_team.users.where(
        id: @model.user_assignments.automatically_assigned.select(:user_id)
      ).or(
        current_team.users.where.not(id: @model.users.select(:id))
      ).order('users.full_name ASC')
    end

    def propagate_job(destroy: false)
      is_group = @assignment.is_a?(UserGroupAssignment)

      UserAssignments::PropagateAssignmentJob.perform_later(
        @model,
        is_group ? @assignment.user_group.id : @assignment.user.id,
        @assignment.user_role,
        current_user.id,
        team_id: current_team.id,
        group: is_group,
        destroy: destroy
      )
    end

    def check_manage_permissions
      raise NotImplementedError
    end

    def check_read_permissions
      raise NotImplementedError
    end

    def log_activity(type_of, message_items = {})
      message_items = { model_parameter => @model.id }.merge(message_items)

      Activities::CreateActivityService
        .call(activity_type: type_of,
              owner: current_user,
              subject: @model,
              team: @model.team,
              project: @project,
              message_items: message_items)
    end

    def set_assignment
      @assignment = @model.public_send(:"#{assignment_type}_assignments").find_or_initialize_by(
        "#{assignment_type}_id": permitted_params[:"#{assignment_type}_id"],
        team: current_team
      )
    end

    def assignment_type
      if permitted_params[:user_id].present?
        :user
      elsif permitted_params[:user_group_id].present?
        :user_group
      elsif permitted_params[:team_id].present?
        :team
      end
    end
  end
end
