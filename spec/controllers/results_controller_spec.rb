# frozen_string_literal: true

require 'rails_helper'

describe ResultsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    result_text: true
  }

  describe 'DELETE destroy' do

    let(:action) { delete :destroy, params: params }
    let(:params) do
      {
        my_module_id: result_text.result.my_module.id,
        id: result_text.result.id
      }
    end

    before do
      result_text.result.archive!(user)
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :destroy_result))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
