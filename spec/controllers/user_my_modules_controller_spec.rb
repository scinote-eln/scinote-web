# frozen_string_literal: true

require 'rails_helper'

describe UserMyModulesController, type: :controller do
  login_user

  include_context 'reference_project_structure'
  let(:other_user) { create :user }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id, user_my_module: { user_id: other_user.id } }
    end

    it 'calls create activity for assigning user to task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :designate_user_to_my_module)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    context 'when a different my_module_id is passed in the body' do
      let(:another_my_module) { create :my_module, experiment: experiment, created_by: user }
      let(:params) do
        { my_module_id: my_module.id,
          user_my_module: { user_id: other_user.id, my_module_id: another_my_module.id } }
      end

      it 'assigns the user to the task from the URL' do
        action
        expect(UserMyModule.last.my_module_id).to eq(my_module.id)
        expect(another_my_module.user_my_modules).to be_empty
      end
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
              .with(hash_including(activity_type: :undesignate_user_from_my_module)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end

    context 'when assignment belongs to a task in another team' do
      let(:other_team_owner) { create :user }
      let(:other_team) { create :team, created_by: other_team_owner }
      let(:other_project) { create :project, team: other_team, created_by: other_team_owner }
      let(:other_experiment) { create :experiment, project: other_project, created_by: other_team_owner }
      let(:other_my_module) { create :my_module, experiment: other_experiment, created_by: other_team_owner }
      let!(:foreign_user_task) { create :user_my_module, user: other_team_owner, my_module: other_my_module }
      let(:params) do
        { my_module_id: my_module.id, id: foreign_user_task.id }
      end

      it 'responds with 404' do
        action
        expect(response).to have_http_status(:not_found)
      end

      it 'does not destroy the assignment' do
        expect { action }.not_to(change { UserMyModule.exists?(foreign_user_task.id) })
      end

      it 'does not create activity' do
        expect { action }.not_to(change { Activity.count })
      end
    end
  end
end
