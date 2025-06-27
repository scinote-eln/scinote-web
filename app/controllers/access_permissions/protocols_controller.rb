# frozen_string_literal: true

module AccessPermissions
  class ProtocolsController < BaseController
    # protocol template activity naming is inconsistent with model name (model_parameter in BaseController),
    # so we need to map them for now
    ACTIVITY_TYPE_MAP = {
      protocol_access_granted_all_team_members: :protocol_template_access_granted_all_team_members,
      protocol_access_revoked_all_team_members: :protocol_template_access_revoked_all_team_members,
      protocol_access_changed_all_team_members: :protocol_template_access_changed_all_team_members,
      protocol_access_granted: :protocol_template_access_granted,
      protocol_access_revoked: :protocol_template_access_revoked,
      protocol_access_changed: :protocol_template_access_changed
    }.freeze

    def destroy
      # prevent deletion of last manually assigned user that can manage users
      raise ActiveRecord::RecordInvalid if params[:user_id].present? && @assignment.last_with_permission?(ProtocolPermissions::USERS_MANAGE, assigned: :manually)

      is_group = @assignment.respond_to?(:user_group)

      Protocol.transaction do
        if !is_group && @model.visible?
          @assignment.update!(
            user_role: @model.default_public_user_role,
            assigned: :automatically
          )
        else
          @assignment.destroy!
        end
        if is_group
          log_activity(:protocol_template_access_revoked_user_group, user_group: @assignment.user_group.id, role: @assignment.user_role.name)
        else
          log_activity(:protocol_template_access_revoked, user_target: @assignment.user.id, role: @assignment.user_role.name)
        end
      end

      render json: { message: t('access_permissions.destroy.success', member_name: is_group ? @assignment.user_group.name : @assignment.user.full_name) }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      render json: { message: t('access_permissions.destroy.failure') }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end

    private

    def set_model
      @model = current_team.protocols.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      return render_404 unless @model

      @model = @model.parent if @model.parent_id
    end

    def check_manage_permissions
      render_403 unless can_manage_protocol_users?(@model)
    end

    def check_read_permissions
      render_403 unless can_read_protocol_in_repository?(@model) || can_manage_team?(@model.team)
    end

    def log_activity(type_of, message_items = {})
      super(ACTIVITY_TYPE_MAP[type_of] || type_of, message_items)
    end
  end
end
