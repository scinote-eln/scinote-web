# frozen_string_literal: true

module AccessPermissions
  class FormsController < ApplicationController
    include InputSanitizeHelper

    before_action :set_form
    before_action :check_read_permissions, only: %i(show show_user_group_assignments)
    before_action :check_manage_permissions, except: %i(show show_user_group_assignments)
    before_action :available_users, only: %i(new create)

    def show
      render json: @form.user_assignments.includes(:user_role, :user).order('users.full_name ASC'),
             each_serializer: UserAssignmentSerializer, user: current_user
    end

    def show_user_group_assignments
      render json: @form.user_group_assignments.includes(:user_role, :user_group).order('user_groups.name ASC'),
             each_serializer: UserGroupAssignmentSerializer, user: current_user
    end

    def new
      render json: @available_users, each_serializer: UserSerializer, user: current_user
    end

    def unassigned_user_groups
      render json: current_team.user_groups.where.not(id: @form.user_group_assignments.select(:user_group_id)),
             each_serializer: UserGroupSerializer, user: current_user
    end

    def edit; end

    def create
      ActiveRecord::Base.transaction do
        created_count = 0
        if permitted_create_params[:user_id] == 'all'
          @form.update!(visibility: :visible, default_public_user_role_id: permitted_create_params[:user_role_id])
          log_activity(:form_access_granted_all_team_members,
                       { team: @form.team.id, role: @form.default_public_user_role&.name })
        else
          assignment_type = assignment_type(permitted_create_params)
          assignment_key = "#{assignment_type}_id".to_sym

          assignment = @form.public_send("#{assignment_type}_assignments").find_or_initialize_by(
            assignment_key => permitted_create_params[assignment_key],
            team: current_team
          )

          assignment.update!(
            user_role_id: permitted_create_params[:user_role_id],
            assigned_by: current_user,
            assigned: :manually
          )

          if permitted_create_params[:user_id].present?
            log_activity(:form_access_granted, user_target: assignment.user.id, role: assignment.user_role.name)
          else
            log_activity(:form_access_granted_user_group, user_group: assignment.user_group.id, role: assignment.user_role.name)
          end

          created_count += 1
        end

        @message = if created_count.zero?
                     t('access_permissions.create.success', member_name: t('access_permissions.all_team'))
                   else
                     t('access_permissions.create.success', member_name: escape_input(assignment.respond_to?(:user_group) ? assignment.user_group.name : assignment.user.name))
                   end
        render json: { message: @message }
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        errors = @form.errors.present? ? @form.errors&.map(&:message)&.join(',') : e.message
        render json: { flash: errors }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end

    def update
      assignment_type = assignment_type(permitted_update_params)
      assignment_key = "#{assignment_type}_id".to_sym

      assignment = @form.public_send("#{assignment_type}_assignments").find_by(
        assignment_key => permitted_update_params[assignment_key],
        team: current_team
      )

      # prevent role change if it would result in no manually assigned users having the user management permission
      new_user_role = UserRole.find(permitted_update_params[:user_role_id])
      if permitted_create_params[:user_id].present? && !new_user_role.has_permission?(FormPermissions::USERS_MANAGE) &&
         assignment.last_with_permission?(FormPermissions::USERS_MANAGE, assigned: :manually)
        raise ActiveRecord::RecordInvalid
      end

      assignment.update!(permitted_update_params)
      if permitted_create_params[:user_id].present?
        log_activity(:form_access_changed, user_target: assignment.user.id, role: assignment.user_role.name)
      else
        log_activity(:form_access_changed_user_group, user_group: assignment.user_group.id, role: assignment.user_role.name)
      end
    rescue ActiveRecord::RecordInvalid
      render json: { flash: t('access_permissions.update.failure') }, status: :unprocessable_entity
    end

    def destroy
      assignment_type = assignment_type(params)
      assignment_key = "#{assignment_type}_id".to_sym

      assignment = @form.public_send("#{assignment_type}_assignments").find_by(
        assignment_key => params[assignment_key],
        team: current_team
      )

      # prevent deletion of last manually assigned user that can manage users
      raise ActiveRecord::RecordInvalid if params[:user_id].present? && assignment.last_with_permission?(FormPermissions::USERS_MANAGE, assigned: :manually)

      is_group = assignment.respond_to?(:user_group)

      Form.transaction do
        if !is_group && @form.visible?
          assignment.update!(
            user_role: @form.default_public_user_role,
            assigned: :automatically
          )
        else
          assignment.destroy!
        end

        if is_group
          log_activity(:form_access_revoked_user_group, user_group: assignment.user_group.id, role: assignment.user_role.name)
        else
          log_activity(:form_access_revoked, user_target: assignment.user.id, role: assignment.user_role.name)
        end
      end

      render json: { message: t('access_permissions.destroy.success', member_name: is_group ? assignment.user_group.name : assignment.user.full_name) }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      render json: { message: t('access_permissions.destroy.failure') }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end

    def update_default_public_user_role
      ActiveRecord::Base.transaction do
        current_role = @form.default_public_user_role.name
        @form.update!(permitted_default_public_user_role_params)

        # revoke all team members access
        if permitted_default_public_user_role_params[:default_public_user_role_id].blank?
          log_activity(:form_access_revoked_all_team_members,
                       { team: @form.team.id, role: current_role })
          render json: { flash: t('access_permissions.update.revoke_all_team_members') }, status: :ok
        else
          # update all team members access
          log_activity(:form_access_changed_all_team_members,
                       { team: @form.team.id, role: @form.default_public_user_role&.name })
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        render json: { flash: @form.errors&.map(&:message)&.join(',') }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end

    private

    def permitted_default_public_user_role_params
      params.require(:object).permit(:default_public_user_role_id)
    end

    def permitted_update_params
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id user_group_id))
    end

    def permitted_create_params
      params.require(:user_assignment)
            .permit(%i(user_id user_role_id user_group_id))
    end

    def available_users
      # automatically assigned or not assigned to project
      @available_users = current_team.users.where(
        id: @form.user_assignments.automatically_assigned.select(:user_id)
      ).or(
        current_team.users.where.not(id: @form.users.select(:id))
      ).order('users.full_name ASC')
    end

    def set_form
      @form = current_team.forms.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      return render_404 unless @form

      @form = @form.parent if @form.parent_id
    end

    def check_manage_permissions
      render_403 unless can_manage_form_users?(@form)
    end

    def check_read_permissions
      render_403 unless can_read_form?(@form) || can_manage_team?(@form.team)
    end

    def assignment_type(permitted_params)
      if permitted_params[:user_id].present?
        'user'
      elsif permitted_params[:user_group_id].present?
        'user_group'
      end
    end

    def log_activity(type_of, message_items = {})
      message_items = { form: @form.id }.merge(message_items)

      Activities::CreateActivityService
        .call(activity_type: type_of,
              owner: current_user,
              subject: @form,
              team: @form.team,
              project: nil,
              message_items: message_items)
    end
  end
end
