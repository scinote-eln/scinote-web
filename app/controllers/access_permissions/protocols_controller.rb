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
      protocol_access_changed: :protocol_template_access_changed,
      protocol_access_granted_user_group: :protocol_template_access_granted_user_group,
      protocol_access_revoked_user_group: :protocol_template_access_revoked_user_group,
      protocol_access_changed_user_group: :protocol_template_access_changed_user_group
    }.freeze

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
