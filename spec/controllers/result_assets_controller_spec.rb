# frozen_string_literal: true

require 'rails_helper'

describe ResultAssetsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let!(:team) { create :team, :with_members }
  let!(:user_project) { create :user_project, :owner, user: user }
  let(:project) do
    create :project, team: team, user_projects: [user_project]
  end
  let(:experiment) { create :experiment, project: project }
  let(:task) { create :my_module, name: 'test task', experiment: experiment }
  let(:result) do
    create :result, name: 'test result', my_module: task, user: user
  end
  let(:result_asset) { create :result_asset, result: result }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: task.id,
        results_names: { '0': 'result name created' },
        results_files:
          { '0': fixture_file_upload('files/export.csv', 'text/csv') } }
    end

    #it 'calls create activity service' do
    #  expect(Activities::CreateActivityService).to receive(:call)
    #    .with(hash_including(activity_type: :add_result))
    #  action
    #end

    #it 'adds activity in DB' do
    #  expect { action }
    #    .to(change { Activity.count })
    #end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      { id: result_asset.id,
        result: { name: result.name } }
    end
    it 'calls create activity service (edit_result)' do
      params[:result][:name] = 'test result changed'
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_result))
      action
    end

    it 'calls create activity service (archive_result)' do
      params[:result][:archived] = 'true'
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :archive_result))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
