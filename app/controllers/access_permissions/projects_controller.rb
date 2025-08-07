# frozen_string_literal: true

module AccessPermissions
  class ProjectsController < AccessPermissions::BaseController
    # legacy activity map
    ACTIVITY_TYPE_MAP = {
      project_access_granted: :assign_user_to_project,
      project_access_changed: :change_user_role_on_project,
      project_access_revoked: :unassign_user_from_project,
      project_access_granted_all_team_members: :project_grant_access_to_all_team_members,
      project_access_changed_all_team_members: :project_access_changed_all_team_members,
      project_access_revoked_all_team_members: :project_remove_access_from_all_team_members
    }.freeze

    private

    def set_model
      @model = current_team.projects.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])
      @project = @model

      render_404 unless @model
    end

    def check_manage_permissions
      render_403 unless can_manage_project_users?(@model)
    end

    def check_read_permissions
      render_403 unless can_read_project_users?(@model)
    end

    def log_activity(type_of, message_items = {})
      super(ACTIVITY_TYPE_MAP[type_of] || type_of, message_items)
    end
  end
end
