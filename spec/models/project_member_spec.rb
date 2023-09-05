# frozen_string_literal: true

require 'rails_helper'

describe ProjectMember, type: :model do
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:user) { create :user }
  let!(:project) { create :project, created_by: user }
  let(:normal_user_role) { create :normal_user_role }

  let(:subject) { described_class.new(user, project, user) }

  describe '#update' do
    let!(:user_project) { create :user_project, user: user, project: project }

    it 'updates only the user assignment role' do
      subject.user_role_id = normal_user_role.id
      subject.update
      expect(subject.user_assignment.user_role).to eq normal_user_role
    end

    it 'logs a change_user_role_on_project activity' do
      subject.user_role_id = normal_user_role.id
      expect {
        subject.update
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'change_user_role_on_project'
    end

    it 'triggers the UserAssignments::PropagateAssignmentJob job' do
      subject.user_role_id = normal_user_role.id
      expect(UserAssignments::PropagateAssignmentJob).to receive(:perform_later).with(
        project, user.id, normal_user_role, user.id
      )
      subject.update
    end
  end

  describe '#destroy' do
    let!(:user_two) { create :user }
    let!(:user_project_two) { create :user_project, user: user_two, project: project }
    let!(:user_assignment_two) do
      create :user_assignment,
             assignable: project,
             user: user_two,
             user_role: owner_role,
             assigned_by: user
    end
    let!(:user_project) { create :user_project, user: user, project: project }
    let!(:user_assignment) { project.user_assignments.first }

    it 'removes the user_assignment and user_project' do
      expect {
        subject.destroy
      }.to change(UserAssignment, :count).by(-1).and \
           change(UserProject, :count).by(-1)
    end

    it 'does not remove the user_assignment and user_project if the user is last owner' do
      user_assignment_two.update!(user_role: normal_user_role)

      expect {
        subject.destroy
      }.to change(UserAssignment, :count).by(0).and \
           change(UserProject, :count).by(0)
    end

    it 'logs a unassign_user_from_project activity' do
      expect {
        subject.destroy
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'unassign_user_from_project'
    end

    it 'triggers the UserAssignments::PropagateAssignmentJob job' do
      expect(UserAssignments::PropagateAssignmentJob).to receive(:perform_later).with(
        project, user.id, owner_role, user.id, destroy: true
      )
      subject.destroy
    end
  end

  describe 'validations' do
    it 'validates presence or user, project, user_role_id when assign is true' do
      subject = described_class.new(nil, nil)
      subject.assign = true
      subject.valid?
      expect(subject.errors).to have_key(:project)
      expect(subject.errors).to have_key(:user)
      expect(subject.errors).to have_key(:user_role_id)
    end

    it 'validates user project assignment existence' do
      subject.assign = true
      subject.user_assignment.user_role_id = owner_role.id
      subject.valid?
      expect(subject.errors).to have_key(:user_role_id)
    end

    describe 'user_role' do
      it 'adds an error when user role does not exist' do
        subject.assign = true
        subject.user_role_id = 1234
        subject.valid?
        expect(subject.errors).to have_key(:user_role_id)
      end

      it 'does not add an error when role exists' do
        project.user_assignments.destroy_all
        subject.assign = true
        subject.user_role_id = owner_role.id
        subject.valid?
        expect(subject.errors).not_to have_key(:user_role_id)
      end
    end
  end
end
