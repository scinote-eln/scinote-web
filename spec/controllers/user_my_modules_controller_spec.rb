# frozen_string_literal: true

require 'rails_helper'

describe UserMyModulesController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:project) { create :project, team: team, created_by: user }
  let!(:user_project) do
    create :user_project, :owner, user: user, project: project
  end
  let(:experiment) { create :experiment, project: project }
  let(:my_module) { create :my_module, experiment: experiment }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id, user_my_module: { user_id: user.id } }
    end

    it 'calls create activity for assigning user to task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :assign_user_to_module)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'DELETE destroy' do
    let(:user_task) { create :user_my_module, user: user, my_module: my_module }
    let(:action) { delete :destroy, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id, id: user_task.id }
    end

    it 'calls create activity for unassigning user to task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :unassign_user_from_module)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
