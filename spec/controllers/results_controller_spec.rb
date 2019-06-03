# frozen_string_literal: true

require 'rails_helper'

describe ResultsController, type: :controller do
  project_generator(results: 1, result_texts: 1)

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params }
    let(:params) do
      { id: @project[:result].id }
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
