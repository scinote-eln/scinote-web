# frozen_string_literal: true

require 'rails_helper'

describe ProjectCommentsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let(:user_team) { create :user_team, team: team, user: user }
  let(:user_project) { create :user_project, :owner, user: user }
  let(:project) do
    create :project, team: team, user_projects: [user_project]
  end
  let(:project_comment) do
    create :project_comment, project: project, user: user
  end

  describe '#create' do
    context 'in JSON format' do
      let(:params) do
        { project_id: project.id,
          comment: { message: 'test message' } }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :add_comment_to_project))

        post :create, params: params, format: :json
      end
    end
  end

  describe '#update' do
    context 'in JSON format' do
      let(:params) do
        { project_id: project.id,
          id: project_comment.id,
          comment: { message: 'test message updated' } }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :edit_project_comment))

        put :update, params: params, format: :json
      end
    end
  end

  describe '#destroy' do
    context 'in JSON format' do
      let(:params) do
        { project_id: project.id,
          id: project_comment.id }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :delete_project_comment))

        delete :destroy, params: params, format: :json
      end
    end
  end
end
