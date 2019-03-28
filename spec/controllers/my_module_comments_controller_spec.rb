# frozen_string_literal: true

require 'rails_helper'

describe MyModuleCommentsController, type: :controller do
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
  let(:task_comment) { create :task_comment, user: user, my_module: my_module }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id, comment: { message: 'comment created' } }
    end

    it 'calls create activity for adding comment to task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :add_comment_to_module)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id,
        id: task_comment.id,
        comment: { message: 'comment updated' } }
    end

    it 'calls create activity for editing comment on task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :edit_module_comment)))
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
      { my_module_id: my_module.id, id: task_comment.id }
    end

    it 'calls create activity for deleting comment on task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_module_comment)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
