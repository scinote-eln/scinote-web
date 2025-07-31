# frozen_string_literal: true

module UserAssignments
  class UpdateTeamUserAssignmentsService
    def initialize(team_user_assignment)
      @user = team_user_assignment.user
      @team = team_user_assignment.assignable
      @user_role = team_user_assignment.user_role
    end

    def call
      update_reports_assignments
    end

    private

    def update_reports_assignments
      @team.reports
           .joins(:automatic_user_assignments)
           .preload(:automatic_user_assignments)
           .where(automatic_user_assignments: { user: @user })
           .find_each do |report|
        report.automatic_user_assignments
              .select { |assignment| assignment.user_id == @user.id }
              .each { |assignment| assignment.update!(user_role: @user_role) }
      end
    end
  end
end
