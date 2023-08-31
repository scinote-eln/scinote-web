# frozen_string_literal: true

module UserAssignments
  class RemoveTeamUserAssignmentsService
    def initialize(team_user_assignment)
      @user = team_user_assignment.user
      @team = team_user_assignment.assignable
    end

    def call
      @team.projects.find_each do |project|
        UserAssignments::PropagateAssignmentJob
          .perform_now(project, @user.id, nil, nil, destroy: true, remove_from_team: true)
      end
      remove_repositories_assignments
      remove_protocols_assignments
      remove_reports_assignments
    end

    private

    def remove_repositories_assignments
      @team.repositories
           .joins(:user_assignments)
           .preload(:user_assignments)
           .where(user_assignments: { user: @user, team: @team }).find_each do |repository|
        repository.user_assignments
                  .select { |assignment| assignment.user_id == @user.id && assignment.team_id == @team.id }
                  .each(&:destroy!)
      end
      @team.repository_sharing_user_assignments.where(user: @user).find_each(&:destroy!)
    end

    def remove_protocols_assignments
      @team.repository_protocols
           .joins(:user_assignments)
           .preload(:user_assignments)
           .where(user_assignments: { user: @user }).find_each do |protocol|
        protocol.user_assignments
                .select { |assignment| assignment.user_id == @user.id }
                .each(&:destroy!)
      end
    end

    def remove_reports_assignments
      @team.reports
           .joins(:user_assignments)
           .preload(:user_assignments)
           .where(user_assignments: { user: @user }).find_each do |report|
        report.user_assignments
              .select { |assignment| assignment.user_id == @user.id }
              .each(&:destroy!)
      end
    end
  end
end
