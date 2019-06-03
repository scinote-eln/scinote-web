# frozen_string_literal: true

require 'rails_helper'

describe MyModuleTagsController, type: :controller do
  project_generator

  describe 'POST create' do
    let(:tag) { create :tag, project: @project[:project] }
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: @project[:my_module].id, my_module_tag: { tag_id: tag.id } }
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
      { my_module_id: @project[:my_module].id, id: my_module_tag.id }
    end
    let(:my_module_tag) { create :my_module_tag, my_module: @project[:my_module] }

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
