# frozen_string_literal: true

module AccessPermissions
  class ProtocolsController < ApplicationController
    before_action :set_protocol
    before_action :check_read_permissions, only: %i(show)
    before_action :check_manage_permissions, except: %i(show)

    def new
      @user_assignment = UserAssignment.new(
        assignable: @protocol,
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
      @user_assignment = @protocol.user_assignments.find_by(
        user_id: permitted_update_params[:user_id],
        team: current_team
      )

      # prevent role change if it would result in no manually assigned users having the user management permission
      new_user_role = UserRole.find(permitted_update_params[:user_role_id])
      if !new_user_role.has_permission?(ProtocolPermissions::USERS_MANAGE) &&
         @user_assignment.last_with_permission?(ProtocolPermissions::USERS_MANAGE, assigned: :manually)
        raise ActiveRecord::RecordInvalid
      end

      @user_assignment.update!(permitted_update_params)
      log_activity(:protocol_template_access_changed, { user_target: @user_assignment.user.id,
                                                        role: @user_assignment.user_role.name })

      respond_to do |format|
        format.json do
          render :protocol_member
        end
      end
    rescue ActiveRecord::RecordInvalid
      render json: { flash: t('access_permissions.update.failure') }, status: :unprocessable_entity
    end

    def create
      ActiveRecord::Base.transaction do
        created_count = 0
        permitted_create_params[:resource_members].each do |_k, user_assignment_params|
          next unless user_assignment_params[:assign] == '1'

          if user_assignment_params[:user_id] == 'all'
            @protocol.update!(default_public_user_role_id: user_assignment_params[:user_role_id])
            log_activity(:protocol_template_access_granted_all_team_members,
                         { team: @protocol.team.id, role: @protocol.default_public_user_role&.name })
          else
            user_assignment = UserAssignment.find_or_initialize_by(
              assignable: @protocol,
              user_id: user_assignment_params[:user_id],
              team: current_team
            )

            user_assignment.update!(
              user_role_id: user_assignment_params[:user_role_id],
              assigned_by: current_user,
              assigned: :manually
            )

            created_count += 1
            log_activity(:protocol_template_access_granted, { user_target: user_assignment.user.id,
                                                              role: user_assignment.user_role.name })
          end
        end

        respond_to do |format|
          @message = if created_count.zero?
                       t('access_permissions.create.success', count: t('access_permissions.all_team'))
                     else
                       t('access_permissions.create.success', count: created_count)
                     end
          format.json { render :edit }
        end

      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        errors = @protocol.errors.present? ? @protocol.errors&.map(&:message)&.join(',') : e.message
        render json: { flash: errors }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end

    def destroy
      user = @protocol.assigned_users.find(params[:user_id])
      user_assignment = @protocol.user_assignments.find_by(user: user, team: current_team)

      # prevent deletion of last manually assigned user that can manage users
      if user_assignment.last_with_permission?(ProtocolPermissions::USERS_MANAGE, assigned: :manually)
        raise ActiveRecord::RecordInvalid
      end

      Protocol.transaction do
        if @protocol.visible?
          user_assignment.update!(
            user_role: @protocol.default_public_user_role,
            assigned: :automatically
          )
        else
          user_assignment.destroy!
        end
        log_activity(:protocol_template_access_revoked, { user_target: user_assignment.user.id,
                                                          role: user_assignment.user_role.name })
      end

      render json: { flash: t('access_permissions.destroy.success', member_name: user.full_name) }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      render json: { flash: t('access_permissions.destroy.failure') }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end

    def update_default_public_user_role
      ActiveRecord::Base.transaction do
        current_role = @protocol.default_public_user_role.name
        @protocol.update!(permitted_default_public_user_role_params)

        # revoke all team members access
        if permitted_default_public_user_role_params[:default_public_user_role_id].blank?
          log_activity(:protocol_template_access_revoked_all_team_members,
                       { team: @protocol.team.id, role: current_role })
          render json: { flash: t('access_permissions.update.revoke_all_team_members') }, status: :ok
        else
          # update all team members access
          log_activity(:protocol_template_access_changed_all_team_members,
                       { team: @protocol.team.id, role: @protocol.default_public_user_role&.name })
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        render json: { flash: @protocol&.errors&.map(&:message)&.join(',') }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end

    private

    def permitted_default_public_user_role_params
      params.require(:protocol).permit(:default_public_user_role_id)
    end

    def permitted_update_params
      params.require(:user_assignment)
            .permit(%i(user_role_id user_id))
    end

    def permitted_create_params
      params.require(:access_permissions_new_user_form)
            .permit(resource_members: %i(assign user_id user_role_id))
    end

    def set_protocol
      @protocol = current_team.protocols.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      return render_404 unless @protocol

      @protocol = @protocol.parent if @protocol.parent_id
    end

    def check_manage_permissions
      render_403 unless can_manage_protocol_users?(@protocol)
    end

    def check_read_permissions
      render_403 unless can_read_protocol_in_repository?(@protocol) || can_manage_team?(@protocol.team)
    end

    def log_activity(type_of, message_items = {})
      message_items = { protocol: @protocol.id }.merge(message_items)

      Activities::CreateActivityService
        .call(activity_type: type_of,
              owner: current_user,
              subject: @protocol,
              team: @protocol.team,
              project: nil,
              message_items: message_items)
    end
  end
end
