# frozen_string_literal: true

require 'rails_helper'

describe ResultAssetsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    result_asset: true
  }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id,
        results_names: { '0': 'result name created' },
        results_files:
          { '0': file_fixture('files/export.csv', 'text/csv') } }
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
        result: { name: result_asset.result.name } }
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
