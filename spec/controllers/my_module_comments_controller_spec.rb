# frozen_string_literal: true

require 'rails_helper'

describe MyModuleCommentsController, type: :controller do
  login_user
  include_context 'reference_project_structure' , {
    team_role: :normal_user,
    my_module_comment: true
  }

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
        id: my_module_comment.id,
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
      { my_module_id: my_module.id, id: my_module_comment.id }
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
