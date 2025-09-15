# frozen_string_literal: true

module TeamAssignmentsActions
  extend ActiveSupport::Concern

  private

  def create_team_assignment(model, activitiy_type)
    user_role_params = create_team_assignment_params(model)
    return if user_role_params[:default_public_user_role_id].blank?

    assignment = model.team_assignments.create!(team: current_team,
                                                assignable: model,
                                                user_role_id: user_role_params[:default_public_user_role_id],
                                                assigned_by: current_user,
                                                assigned: :manually)
    propagate_job(model, assignment)
    log_activity_team_assignment(model, activitiy_type, team: assignment.team.id, role: assignment.user_role.name)
  end

  def create_team_assignment_params(model)
    params.require(model.class.name.underscore.to_sym).permit(:default_public_user_role_id)
  end

  def propagate_job(model, assignment)
    return unless model.has_permission_children?

    UserAssignments::PropagateAssignmentJob.perform_later(assignment)
  end

  def log_activity_team_assignment(model, type_of, message_items = {})
    message_items = { model.class.permission_class.model_name.param_key => model.id }.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: model,
            team: model.team,
            project: @project,
            message_items: message_items)
  end
end
