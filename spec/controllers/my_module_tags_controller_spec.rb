# frozen_string_literal: true

require 'rails_helper'

describe MyModuleTagsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:project) { create :project, created_by: user }
  let!(:user_project) do
    create :user_project, :normal_user, user: user, project: project
  end
  let(:experiment) { create :experiment, project: project }
  let(:my_module) { create :my_module, experiment: experiment }

  describe 'POST create' do
    let(:tag) { create :tag, project: project }
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id, my_module_tag: { tag_id: tag.id } }
    end

    it 'calls create activity for creating task tag' do
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

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id, id: my_module_tag.id }
    end
    let(:my_module_tag) { create :my_module_tag, my_module: my_module }

    it 'calls create activity for deleting task tag' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :remove_task_tag)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
