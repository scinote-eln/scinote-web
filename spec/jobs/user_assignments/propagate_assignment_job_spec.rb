# frozen_string_literal: true
require 'rails_helper'

module UserAssignments
  RSpec.describe PropagateAssignmentJob, type: :job do

    let!(:technician_role) { create :technician_role }
    let!(:user_one) { create :user }
    let!(:user_two) { create :user }
    let!(:team) { create :team, created_by: user_one }
    let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
    let!(:project) { create :project, team: team, created_by: user_one }
    let!(:user_project) { create :user_project, user: user_one, project: project }
    let!(:experiment_one) { create :experiment, project: project }
    let!(:experiment_two) { create :experiment, project: project }
    let!(:my_module_one) { create :my_module, experiment: experiment_one, created_by: experiment_one.created_by }
    let!(:my_module_two) { create :my_module, experiment: experiment_two, created_by: experiment_two.created_by }
    let!(:user_assignment) do
      create :user_assignment,
             assignable: project,
             user: user_one,
             user_role: owner_role,
             assigned_by: user_one
    end

    before do
      [user_one, user_two].each do |user|
        create :user_team, :admin, user: user, team: team
      end
    end

    describe 'perform' do
      it 'propagates the user assignments to project child object' do
        expect {
          described_class.perform_now(project, user_two, technician_role, user_one)
        }.to change(UserAssignment, :count).by(4)
      end

      it 'propagates the user assignments to project child object with the same role' do
        described_class.perform_now(project, user_two, technician_role, user_one)
        [
          UserAssignment.find_by(user: user_two, assignable: experiment_one),
          UserAssignment.find_by(user: user_two, assignable: experiment_two),
          UserAssignment.find_by(user: user_two, assignable: my_module_one),
          UserAssignment.find_by(user: user_two, assignable: my_module_two),
        ].each do |user_assignment|
          expect(user_assignment.user_role).to eq technician_role
        end
      end

      it 'removes all the child objects user assignments when the destroy flag is set' do
        create :user_assignment, assignable: experiment_one, user: user_two, user_role: technician_role, assigned_by: user_one
        create :user_assignment, assignable: experiment_two, user: user_two, user_role: technician_role, assigned_by: user_one
        create :user_assignment, assignable: my_module_one, user: user_two, user_role: technician_role, assigned_by: user_one
        create :user_assignment, assignable: my_module_two, user: user_two, user_role: technician_role, assigned_by: user_one

        expect {
          described_class.perform_now(project, user_two, technician_role, user_one, destroy: true)
        }.to change(UserAssignment, :count).by(-4)
      end

      it 'does not propagate the user assignment if the object was manually assigned' do
        experiment_assignment = create :user_assignment,
                                       assignable: experiment_one,
                                       user: user_two,
                                       user_role: owner_role,
                                       assigned_by: user_one,
                                       assigned: :manually
        described_class.perform_now(project, user_two, technician_role, user_one)
        expect(experiment_assignment.reload.user_role).to eq owner_role
      end

      it 'does propagate the user assignment if the object was automatically assigned' do
        experiment_assignment = create :user_assignment,
                                       assignable: experiment_one,
                                       user: user_two,
                                       user_role: owner_role,
                                       assigned_by: user_one,
                                       assigned: :automatically
        described_class.perform_now(project, user_two, technician_role, user_one)
        expect(experiment_assignment.reload.user_role).to eq technician_role
      end
    end
  end
end
