# frozen_string_literal: true

module UserAssignments
  class CreateTeamUserAssignmentsService
    def initialize(team_user_assignment)
      @user = team_user_assignment.user
      @team = team_user_assignment.assignable
      @user_role = team_user_assignment.user_role
      @assigned_by = team_user_assignment.assigned_by
      @viewer_role = UserRole.find_predefined_viewer_role
    end

    def call
      create_reports_assignments
    end

    private

    def create_reports_assignments
      @team.reports.find_each do |report|
        create_or_update_user_assignment(report)
      end
    end

    def create_or_update_user_assignment(object, role = nil)
      new_user_assignment = object.user_assignments.find_or_initialize_by(user: @user, team: object.team)
      return if new_user_assignment.manually_assigned?

      new_user_assignment.user_role = role || @user_role
      new_user_assignment.assigned_by = @assigned_by
      new_user_assignment.assigned = :automatically
      new_user_assignment.save!
    end
  end
end
