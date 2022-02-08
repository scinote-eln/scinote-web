# frozen_string_literal: true

require 'rails_helper'

describe MyModuleMember, type: :model do
  # let(:owner_role) { create :owner_role }
  let!(:user) { create :user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:project) { create :project }
  let!(:user_project) { create :user_project, user: user, project: project }
  let!(:user_assignment) do
    create :user_assignment,
           assignable: project,
           user: user,
           user_role: owner_role,
           assigned_by: user
  end
  let!(:experiment) { create :experiment, project: project, created_by: project.created_by }
  let!(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:normal_user_role) { create :normal_user_role }

  describe '#update' do
    let!(:valid_params) do
      {
        user_id: user.id,
        user_role_id: normal_user_role.id
      }
    end

    let!(:subject) { described_class.new(user, my_module, experiment, project, user) }

    it 'updates the assigment user role' do
      subject.update(valid_params)
      expect(subject.user_assignment.user_role).to eq normal_user_role
    end

    it 'logs a change_user_role_on_my_module activity' do
      expect {
        subject.update(valid_params)
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'change_user_role_on_my_module'
    end
  end
end
