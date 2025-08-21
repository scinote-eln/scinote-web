# frozen_string_literal: true

module AccessPermissions
  class ExperimentsController < BaseController
    before_action :set_project

    def update
      if permitted_params[:user_role_id] == 'reset'
        parent_assignment = @project.public_send(:"#{assignment_type}_assignments").find_or_initialize_by(
          "#{assignment_type}_id": permitted_params[:"#{assignment_type}_id"] || current_team.id,
          team: current_team
        )

        @assignment.update!(
          user_role_id: parent_assignment.user_role_id,
          assigned_by: current_user,
          assigned: :automatically
        )
      else
        @assignment.update!(
          user_role_id: permitted_params[:user_role_id],
          assigned_by: current_user,
          assigned: :manually
        )
      end

      UserAssignments::PropagateAssignmentJob.perform_later(@assignment)

      case assignment_type
      when :team
        log_activity(:experiment_access_changed_all_team_members, team: @assignment.team.id, role: @assignment.user_role.name)
      when :user_group
        log_activity(:experiment_access_changed_user_group, user_group: @assignment.user_group.id, role: @assignment.user_role.name)
      when :user
        log_activity(:change_user_role_on_experiment, user_target: @assignment.user.id, role: @assignment.user_role.name)
      end

      render json: { user_role_id: @assignment.user_role_id }, status: :ok
    end

    private

    def set_project
      @project = @model.project
    end

    def set_model
      @model = Experiment.includes(user_assignments: %i(user user_role)).find_by(id: params[:id])

      render_404 unless @model
    end

    def check_manage_permissions
      render_403 unless can_manage_experiment_users?(@model)
    end

    def check_read_permissions
      render_403 unless can_read_experiment?(@model)
    end
  end
end
