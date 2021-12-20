# frozen_string_literal: true

require 'rails_helper'

describe StepCommentsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    step: true,
    step_comment: true
  }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { step_id: step.id, comment: { message: 'comment created' } }
    end

    it 'calls create activity for adding comment to step' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :add_comment_to_step)))
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
      { step_id: step.id,
        id: step_comment.id,
        comment: { message: 'comment updated' } }
    end

    it 'calls create activity for editing comment on step' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :edit_step_comment)))
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
      { step_id: step.id, id: step_comment.id }
    end

    it 'calls create activity for deleting comment on step' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_step_comment)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
