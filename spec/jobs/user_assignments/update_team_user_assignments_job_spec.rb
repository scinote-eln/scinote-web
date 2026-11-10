# frozen_string_literal: true

require 'rails_helper'

module UserAssignments
  RSpec.describe UpdateTeamUserAssignmentsJob, type: :job do
    let(:owner) { create :user }
    let(:member) { create :user }
    let(:team) { create :team, created_by: owner }
    let(:project) { create :project, team: team, created_by: owner }
    let(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }
    let(:technician_role) do
      UserRole.find_by(name: I18n.t('user_roles.predefined.technician')) || create(:technician_role)
    end
    let!(:team_assignment) { create_user_assignment(team, viewer_role, member, owner) }
    let!(:report) { create :report, user: owner, project: project, team: team }

    it 'updates the role of the automatic report assignments of the user' do
      report_assignment = UserAssignment.find_by!(user: member, assignable: report)
      expect(report_assignment.user_role).to eq viewer_role
      team_assignment.update!(user_role: technician_role)

      # the job calls UpdateTeamUserAssignmentsService.new with one argument, the service requires two
      pending 'bug: job raises ArgumentError instead of updating the report assignments'
      described_class.perform_now(team_assignment, user_id: owner.id)

      expect(report_assignment.reload.user_role).to eq technician_role
    end

    it 'does not touch assignments of other users' do
      other_assignment = UserAssignment.find_by!(user: owner, assignable: report)
      other_assignment.update!(user_role: technician_role)
      team_assignment.update!(user_role: technician_role)

      pending 'bug: job raises ArgumentError instead of updating only the assignments of the given user'
      described_class.perform_now(team_assignment, user_id: owner.id)

      expect(other_assignment.reload.user_role).to eq technician_role
      expect(UserAssignment.find_by!(user: member, assignable: report).user_role).to eq technician_role
    end
  end
end
