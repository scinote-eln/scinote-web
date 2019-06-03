# frozen_string_literal: true

require 'rails_helper'

describe ResultTextsController, type: :controller do
  project_generator(results: 1, result_texts: 1)

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: @project[:my_module].id,
        result: { name: 'result name created',
                  result_text_attributes: { text: 'result text created' } } }
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

  describe '#update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      { id: @project[:result_text].id,
        result: { name: @project[:result].name } }
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
