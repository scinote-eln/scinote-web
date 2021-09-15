# frozen_string_literal: true

require 'rails_helper'

describe TagsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    tag: true
  }

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
