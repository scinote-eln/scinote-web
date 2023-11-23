# frozen_string_literal: true

require 'rails_helper'

describe ResultTextsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    result_text: true
  }

  describe '#update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      { id: result_text.id,
        result: { name: result_text.result.name } }
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
