# frozen_string_literal: true

require 'rails_helper'

describe ResultCommentsController, type: :controller do
  project_generator(results: 1, result_texts: 1, result_comments: 1)

  describe 'POST create' do
    context 'in JSON format' do
      let(:action) { post :create, params: params, format: :json }
      let(:params) do
        { result_id: @project[:result].id,
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
        { result_id: @project[:result].id,
          id: @project[:result_comment].id,
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
      { result_id: @project[:result].id,
        id: @project[:result_comment].id }
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
