# frozen_string_literal: true

require 'rails_helper'

describe ResultCommentsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user, users: [user] }
  let!(:user_project) { create :user_project, :owner, user: user }
  let(:project) do
    create :project, team: team, user_projects: [user_project]
  end
  let(:experiment) { create :experiment, project: project }
  let(:task) { create :my_module, name: 'test task', experiment: experiment }
  let(:result) do
    create :result, name: 'test result', my_module: task, user: user
  end
  let!(:result_text) do
    create :result_text, text: 'test text result', result: result
  end
  let(:result_comment) do
    create :result_comment, message: 'test comment result',
                            result: result,
                            user: user
  end

  describe 'POST create' do
    context 'in JSON format' do
      let(:action) { post :create, params: params, format: :json }
      let(:params) do
        { result_id: result.id,
          comment: { message: 'test comment' } }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :add_comment_to_result))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'PUT update' do
    context 'in JSON format' do
      let(:action) { put :update, params: params, format: :json }
      let(:params) do
        { result_id: result.id,
          id: result_comment.id,
          comment: { message: 'test comment updated' } }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :edit_result_comment))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params, format: :json }
    let(:params) do
      { result_id: result.id,
        id: result_comment.id }
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :delete_result_comment))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
