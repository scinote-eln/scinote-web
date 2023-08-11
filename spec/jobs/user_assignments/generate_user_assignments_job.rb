# frozen_string_literal: true
require 'rails_helper'

module UserAssignments
  RSpec.describe GenerateUserAssignmentsJob, type: :job do
    let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
    let!(:viewer_role) { create :viewer_role }
    let!(:technician_role) { create :technician_role }
    let!(:user_one) { create :user }
    let!(:user_two) { create :user }
    let!(:user_three) { create :user }
    let!(:team) { create :team, created_by: user_one }
    let!(:project) { create :project, team: team, created_by: user_one }

    before(:each) do
      available_roles = [owner_role, viewer_role, technician_role]
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
          described_class.perform_now(experiment, user_one.id)
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
          described_class.perform_now(my_module, user_one.id)
          user_two_assignment = UserAssignment.find_by(user: user_two, assignable: my_module)
          user_three_assignment = UserAssignment.find_by(user: user_three, assignable: my_module)
          expect(user_two_assignment.user_role).to eq viewer_role
          expect(user_three_assignment.user_role).to eq technician_role
        end
      end
    end
  end
end
