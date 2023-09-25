# frozen_string_literal: true

module UserAssignments
  class UpdateTeamUserAssignmentsService
    def initialize(team_user_assignment)
      @user = team_user_assignment.user
      @team = team_user_assignment.assignable
      @user_role = team_user_assignment.user_role
    end

    def call
      update_repositories_assignments
      update_reports_assignments
    end

    private

    def update_repositories_assignments
      @team.repositories
           .joins(:user_assignments)
           .preload(:user_assignments)
           .where(user_assignments: { user: @user, team: @team })
           .find_each do |repository|
        repository.user_assignments
                  .select { |assignment| assignment[:user_id] == @user.id && assignment[:team_id] == @team.id }
                  .each { |assignment| assignment.update!(user_role: @user_role) }
      end
      @team.repository_sharing_user_assignments.where(user: @user).find_each do |assignment|
        assignment.update!(user_role: @user_role)
      end
    end

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
