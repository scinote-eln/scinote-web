# frozen_string_literal: true

module UserAssignments
  class UpdateTeamUserAssignmentService
    def initialize(user, team, user_role)
      @user = user
      @team = team
      @user_role = user_role
    end

    def call
      update_repositories_assignments
      update_protocols_assignments
      update_reports_assignments
    end

    private

    def update_repositories_assignments
      @team.repositories
           .joins(:automatic_user_assignments)
           .preload(:automatic_user_assignments)
           .where(automatic_user_assignments: { user: @user, team: @team })
           .find_each do |repository|
        repository.automatic_user_assignments
                  .select { |assignment| assignment[:user_id] == @user.id && assignment[:team_id] == @team.id }
                  .each { |assignment| assignment.update!(user_role: @user_role) }
      end
    end

    def update_protocols_assignments
      @team.repository_protocols
           .joins(:automatic_user_assignments)
           .preload(:automatic_user_assignments)
           .where(automatic_user_assignments: { user: @user })
           .find_each do |protocol|
        protocol.automatic_user_assignments
                .select { |assignment| assignment.user_id == @user.id }
                .each { |assignment| assignment.update!(user_role: @user_role) }
      end
    end

    def update_reports_assignments
      @team.reports
           .joins(:automatic_user_assignments)
           .preload(:automatic_user_assignments)
           .where(automatic_user_assignments: { user: @user })
           .find_each do |report|
        report.automatic_user_assignments
              .select { |assignment| assignment.user_id == @user.id && assignment.automatically_assigned? }
              .each { |assignment| assignment.update!(user_role: @user_role) }
      end
    end
  end
end
