# frozen_string_literal: true

require 'rails_helper'

describe TagsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:project) { create :project, team: team, created_by: user }
  let!(:user_project) do
    create :user_project, :normal_user, user: user, project: project
  end
  let(:experiment) { create :experiment, project: project }
  let(:my_module) { create :my_module, experiment: experiment }
  let(:tag) { create :tag, project: project }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      {
        my_module_id: my_module.id,
        project_id: project.id,
        tag: { project_id: project.id,
               name: 'name',
               color: '#123456' }
      }
    end

    it 'calls create activity for create tag' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :create_tag)))
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :add_task_tag)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) do
      put :update, params: {
        project_id: tag.project.id,
        id: tag.id,
        my_module_id: my_module.id,
        tag: { name: 'Name2' }
      }, format: :json
    end

    it 'calls create activity for edit tag' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :edit_tag)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'DELETE destroy' do
    let(:action) do
      delete :destroy, params: {
        project_id: tag.project.id,
        id: tag.id,
        my_module_id: my_module.id,
        format: :json
      }
    end

    it 'calls create activity for delete tag' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_tag)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
