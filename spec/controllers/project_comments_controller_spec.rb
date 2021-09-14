# frozen_string_literal: true

require 'rails_helper'

describe ProjectCommentsController, type: :controller do
  login_user
  include_context 'reference_project_structure', {
    project_comment: true
  }
  describe 'POST create' do
    context 'in JSON format' do
      let(:action) { post :create, params: params, format: :json }
      let(:params) do
        { project_id: project.id,
          comment: { message: 'test message' } }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :add_comment_to_project))

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
        { project_id: project.id,
          id: project_comment.id,
          comment: { message: 'test message updated' } }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :edit_project_comment))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'DELETE destroy' do
    context 'in JSON format' do
      let(:action) { delete :destroy, params: params, format: :json }
      let(:params) do
        { project_id: project.id,
          id: project_comment.id }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :delete_project_comment))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end
end
