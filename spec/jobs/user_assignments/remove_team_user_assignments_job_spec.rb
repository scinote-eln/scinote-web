# frozen_string_literal: true

require 'rails_helper'

module UserAssignments
  RSpec.describe RemoveTeamUserAssignmentsJob, type: :job do
    let(:owner) { create :user }
    let(:member) { create :user }
    let(:team) { create :team, created_by: owner }
    let(:project) { create :project, team: team, created_by: owner }
    let(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }
    let!(:team_assignment) { create_user_assignment(team, viewer_role, member, owner) }
    let!(:report) { create :report, user: owner, project: project, team: team }

    it 'removes the report assignment of the user and the team assignment itself' do
      expect(UserAssignment.exists?(user: member, assignable: report)).to be true

      described_class.perform_now(team_assignment, assigner_id: owner.id)

      expect(UserAssignment.exists?(user: member, assignable: report)).to be false
      expect(UserAssignment.exists?(team_assignment.id)).to be false
    end

    it 'removes project assignments of the user' do
      project_assignment = create_user_assignment(project, viewer_role, member, owner)

      described_class.perform_now(team_assignment, assigner_id: owner.id)

      expect(UserAssignment.exists?(project_assignment.id)).to be false
    end

    it 'keeps assignments of other users' do
      owner_report_assignment = UserAssignment.find_by!(user: owner, assignable: report)

      described_class.perform_now(team_assignment, assigner_id: owner.id)

      expect(UserAssignment.exists?(owner_report_assignment.id)).to be true
    end
  end
end
