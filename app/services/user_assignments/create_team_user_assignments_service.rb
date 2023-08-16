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
      create_public_projects_assignments
      create_repositories_assignments
      create_protocols_assignments
      create_reports_assignments
    end

    private

    def create_public_projects_assignments
      @team.projects.visible.find_each do |project|
        UserAssignments::ProjectGroupAssignmentJob.perform_later(
          @team,
          project,
          @assigned_by&.id
        )
      end
    end

    def create_repositories_assignments
      @team.repositories.find_each do |repository|
        create_or_update_user_assignment(repository)
      end

      @team.team_shared_repositories.find_each do |team_shared_repository|
        next if team_shared_repository.shared_object.blank?

        @team.repository_sharing_user_assignments.create!(
          user: @user,
          user_role: @user_role,
          assignable: team_shared_repository.shared_object,
          assigned: :automatically
        )
      end

      Repository.globally_shared.where.not(team: @team).find_each do |repository|
        @team.repository_sharing_user_assignments.create!(
          user: @user,
          user_role: @user_role,
          assignable: repository,
          assigned: :automatically
        )
      end
    end

    def create_protocols_assignments
      @team.repository_protocols.visible.find_each do |protocol|
        create_or_update_user_assignment(protocol, @viewer_role)
      end
    end

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
