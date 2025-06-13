# frozen_string_literal: true

require 'rails_helper'

describe StepResultsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    my_modules: 1,
    step: true,
    result_text: true
  }

  let(:step_second) { create :step, protocol: my_modules.first.protocol, user: user }
  let(:result_second) { create :result, my_module: my_modules.first, user: user }
  let(:step_result) { create :step_result, step: step_second, result:  result_second }

  describe 'POST create link result succesfully' do
    let(:action) { post :link_results, params: params }
    let(:params) do
      {
        step_ids:[step.id],
        result_ids: [result_text.result.id]
      }
    end

    it 'calls create activity service' do
      action
      expect(response).to have_http_status(:success)
    end

    it 'calls create activity service' do
      params[:step_ids] = [step_second.id]
      action
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST create link step succesfully' do
    let(:action) { delete :link_steps, params: params, format: :json }
    let(:params) do
      {
        step_ids:[step.id],
        result_ids: [result_text.result.id]
      }
    end

    it 'calls create activity service' do
      action
      expect(response).to have_http_status(:success)
    end
  end
end
