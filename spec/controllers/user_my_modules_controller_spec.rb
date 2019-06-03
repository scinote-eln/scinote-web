# frozen_string_literal: true

require 'rails_helper'

describe UserMyModulesController, type: :controller do
  project_generator

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: @project[:my_module].id, user_my_module: { user_id: @project[:user].id } }
    end

    it 'calls create activity for assigning user to task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :assign_user_to_module)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'DELETE destroy' do
    let(:user_task) { create :user_my_module, user: @project[:user], my_module: @project[:my_module] }
    let(:action) { delete :destroy, params: params, format: :json }
    let(:params) do
      { my_module_id: @project[:my_module].id, id: user_task.id }
    end

    it 'calls create activity for unassigning user to task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :unassign_user_from_module)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
