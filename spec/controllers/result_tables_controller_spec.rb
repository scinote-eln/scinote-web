# frozen_string_literal: true

require 'rails_helper'

describe ResultTablesController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    result_table: true
  }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id,
        result:
          { name: 'result name created',
            table_attributes:
              { contents: '{\"data\":[[\"a\",\"b\",\"1\",null,null]]}',
                metadata: "{\"cells\":[{\"row\":\"0\",\"col\":\"0\",\"className\":\"\",\"calculated\":\"\"}]}" } } }
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :add_result))
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
      { id: result_table.id,
        result: { name: result_table.result.name } }
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
      params[:result][:archived] = 'true'
      expect { action }
        .to(change { Activity.count })
    end
  end
end
