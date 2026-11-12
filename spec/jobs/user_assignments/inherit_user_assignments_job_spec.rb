# frozen_string_literal: true
require 'rails_helper'

module UserAssignments
  RSpec.describe InheritUserAssignmentsJob, type: :job do
    let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }
    let!(:technician_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.technician')) || create(:technician_role) }
    let!(:user_one) { create :user }
    let!(:user_two) { create :user }
    let!(:user_three) { create :user }
    let!(:team) { create :team, created_by: user_one }
    let!(:project) { create :project, team: team, created_by: user_one }

    before(:each) do
      create :user_assignment, user: user_two, assignable: project, user_role: viewer_role, assigned_by: user_one

      create :user_assignment, user: user_three, assignable: project, user_role: technician_role, assigned_by: user_one
    end

    describe 'perform' do
      context 'experiment' do
        let!(:experiment) { create :experiment, project: project, created_by: project.created_by }

        it 'user assignments should be created automatically upon experiment creation' do
          # check that all users are assigned
          experiment.reload
          expect([user_one, user_two, user_three] - experiment.user_assignments.reload.map(&:user)).to eq([])
        end

        it 'assigns the same role as the user had on project level' do
          described_class.perform_now(experiment, assigner_id: user_one.id)
          user_two_assignment = UserAssignment.find_by(user: user_two, assignable: experiment)
          user_three_assignment = UserAssignment.find_by(user: user_three, assignable: experiment)
          expect(user_two_assignment.user_role).to eq viewer_role
          expect(user_three_assignment.user_role).to eq technician_role
        end
      end

      context 'my_module' do
        let!(:experiment) { create :experiment, project: project, created_by: project.created_by }
        let!(:my_module) { create :my_module, experiment: experiment, created_by: experiment.created_by }

        it 'user assignments should be created automatically upon my_module creation' do
          # check that all users are assigned
          my_module.reload
          expect([user_one, user_two, user_three] - my_module.user_assignments.reload.map(&:user)).to eq([])
        end

        it 'assigns the same role as the user had on project level' do
          described_class.perform_now(my_module, assigner_id: user_one.id)
          user_two_assignment = UserAssignment.find_by(user: user_two, assignable: my_module)
          user_three_assignment = UserAssignment.find_by(user: user_three, assignable: my_module)
          expect(user_two_assignment.user_role).to eq viewer_role
          expect(user_three_assignment.user_role).to eq technician_role
        end
      end

      context 'manually assigned experiment assignment' do
        let!(:experiment) { create :experiment, project: project, created_by: project.created_by }

        it 'is not overwritten by the project role' do
          assignment = UserAssignment.find_by(user: user_two, assignable: experiment)
          assignment.update!(user_role: technician_role, assigned: :manually)

          described_class.perform_now(experiment, assigner_id: user_one.id)

          expect(assignment.reload.user_role).to eq technician_role
        end
      end

      context 'experiment with team assignments' do
        let!(:experiment) { create :experiment, project: project, created_by: project.created_by }

        it 'copies project team assignments' do
          create :team_assignment, team: team, assignable: project, user_role: viewer_role, assigned_by: user_one
          described_class.perform_now(experiment, assigner_id: user_one.id)

          expect(TeamAssignment.find_by(team: team, assignable: experiment).user_role).to eq viewer_role
        end

        it 'copies project user group assignments' do
          group = create :user_group, team: team, created_by: user_one
          create :user_group_assignment, user_group: group, assignable: project, user_role: viewer_role,
                                         assigned_by: user_one, team: team
          described_class.perform_now(experiment, assigner_id: user_one.id)

          expect(UserGroupAssignment.find_by(user_group: group, assignable: experiment).user_role).to eq viewer_role
        end
      end

      context 'report' do
        let!(:report) { create :report, user: user_one, project: project, team: team }

        it 'assigns team users to the report with their team role' do
          create_user_assignment(team, viewer_role, user_two, user_one)
          described_class.perform_now(report, assigner_id: user_one.id)

          expect(UserAssignment.find_by(user: user_two, assignable: report).user_role).to eq viewer_role
        end
      end

      context 'protocol' do
        let!(:protocol) { create :protocol, :in_repository_published_original, team: team, added_by: user_one }

        it 'syncs parent assignments to a draft child protocol' do
          parent = create :protocol, :in_repository_published_original, team: team, added_by: user_one
          create :user_assignment, user: user_two, assignable: parent, user_role: viewer_role,
                                   assigned_by: user_one, team: team
          draft = create :protocol, :in_repository_draft, team: team, added_by: user_one, parent: parent,
                                           version_number: 2
          described_class.perform_now(draft, assigner_id: user_one.id)

          expect(UserAssignment.find_by(user: user_two, assignable: draft).user_role).to eq viewer_role
        end
      end
    end
  end
end
