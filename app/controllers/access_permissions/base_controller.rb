# frozen_string_literal: true

module AccessPermissions
  class BaseController < ApplicationController
    include InputSanitizeHelper
    include UserRolesHelper

    before_action :set_model
    before_action :set_assignment, only: %i(create update destroy)
    before_action :check_read_permissions, only: %i(show show_user_group_assignments user_roles)
    before_action :check_manage_permissions, except: %i(show show_user_group_assignments user_roles)
    before_action :load_available_users, only: %i(new create)

    def show
      render json: @model.user_assignments.where(team: current_team).includes(:user_role, :user).order('users.full_name ASC'),
             each_serializer: UserAssignmentSerializer, user: current_user
    end

    def new
      render json: @available_users, each_serializer: UserSerializer, user: current_user
    end

    def edit; end

    def create
      ActiveRecord::Base.transaction do
        @assignment.update!(
          user_role_id: permitted_params[:user_role_id],
          assigned_by: current_user,
          assigned: :manually
        )

        case assignment_type
        when :team
          log_activity(:"#{model_parameter}_access_granted_all_team_members", team: @assignment.team.id, role: @assignment.user_role.name)
        when :user
          log_activity(:"#{model_parameter}_access_granted", user_target: @assignment.user.id, role: @assignment.user_role.name)
        when :user_group
          log_activity(:"#{model_parameter}_access_granted_user_group", user_group: @assignment.user_group.id, role: @assignment.user_role.name)
        end

        propagate_job

        @message = if assignment_type == :team
                     t('access_permissions.create.success', member_name: t('access_permissions.all_team'))
                   else
                     t('access_permissions.create.success', member_name: escape_input(assignment_type == :user_group ? @assignment.user_group.name : @assignment.user.name))
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
      if permitted_params[:user_id].present? && permitted_params[:user_id] != 'all' && !new_user_role.has_permission?(manage_permission_constant) &&
         @assignment.last_with_permission?(manage_permission_constant, assigned: :manually)
        raise ActiveRecord::RecordInvalid
      end

      @assignment.update!(user_role_id: permitted_params[:user_role_id], assigned_by: current_user)

      case assignment_type
      when :team
        log_activity(:"#{model_parameter}_access_changed_all_team_members", team: @assignment.team.id, role: @assignment.user_role.name)
      when :user
        log_activity(:"#{model_parameter}_access_changed", user_target: @assignment.user.id, role: @assignment.user_role.name)
      when :user_group
        log_activity(:"#{model_parameter}_access_changed_user_group", user_group: @assignment.user_group.id, role: @assignment.user_role.name)
      end

      propagate_job
    rescue ActiveRecord::RecordInvalid
      render json: { flash: t('access_permissions.update.failure') }, status: :unprocessable_entity
    end

    def destroy
      # prevent deletion of last manually assigned user that can manage users
      if params[:user_id].present? && params[:user_id] != 'all' && @assignment.last_with_permission?(manage_permission_constant, assigned: :manually)
        raise ActiveRecord::RecordInvalid
      end

      UserAssignments::PropagateAssignmentJob.perform_now(@assignment, destroy: true)

      case assignment_type
      when :team
        @assigned_name = @assignment.team.name
        log_activity(:"#{model_parameter}_access_revoked_all_team_members", team: @assignment.team.id, role: @assignment.user_role.name)
      when :user_group
        @assigned_name = @assignment.user_group.name
        log_activity(:"#{model_parameter}_access_revoked_user_group", user_group: @assignment.user_group.id, role: @assignment.user_role.name)
      when :user
        @assigned_name = @assignment.user.full_name
        log_activity(:"#{model_parameter}_access_revoked", user_target: @assignment.user.id, role: @assignment.user_role.name)
      end

      render json: { message: t('access_permissions.destroy.success', member_name: escape_input(@assigned_name)) }
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

    def user_roles
      render json: { data: user_roles_collection(@model).map(&:reverse) }
    end

    private

    def model_parameter
      @model.class.permission_class.name.parameterize.to_sym
    end

    def manage_permission_constant
      "#{@model.class.permission_class.name}Permissions::USERS_MANAGE".constantize
    end

    def permitted_default_public_user_role_params
      params.require(:object).permit(:default_public_user_role_id)
    end

    def permitted_params
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id user_group_id team_id))
    end

    def load_available_users
      @available_users = current_team.users.where.not(id: @model.user_assignments.where(team: current_team).select(:user_id)).order(users: { full_name: :asc })
    end

    def propagate_job(destroy: false)
      return unless @model.has_permission_children?

      UserAssignments::PropagateAssignmentJob.perform_later(
        @assignment,
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
      case assignment_type
      when :user, :user_group
        @assignment = @model.public_send(:"#{assignment_type}_assignments").find_or_initialize_by(
          "#{assignment_type}_id": permitted_params[:"#{assignment_type}_id"],
          team: current_team
        )
      when :team
        @assignment =
          @model.team_assignments
                .find_or_initialize_by(team: current_team, assignable: @model)
      end
    end

    def assignment_type
      if permitted_params[:team_id].present? || permitted_params[:user_id] == 'all'
        :team
      elsif permitted_params[:user_group_id].present?
        :user_group
      elsif permitted_params[:user_id].present?
        :user
      end
    end
  end
end
