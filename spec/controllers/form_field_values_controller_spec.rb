# frozen_string_literal: true

require 'rails_helper'

describe FormFieldValuesController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  let!(:form) { create(:form, team: team, created_by: user) }
  let!(:form_response) { create(:form_response, form: form, created_by: user) }
  let!(:form_field) { create(:form_field, form: form, created_by: user, data: { type: 'TextField' }) }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      {
        form_response_id: form_response.id,
        form_field_value: {
          form_field_id: form_field.id,
          value: 'Test value'
        }
      }
    end

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_submit_form_response?).and_return(true) }

      it 'creates a form field value successfully' do
        expect { action }.to change(FormFieldValue, :count).by(1)
        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body['data']['attributes']['value']).to eq 'Test value'
        expect(response_body['data']['attributes']['form_field_id']).to eq form_field.id
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_submit_form_response?).and_return(false) }

      it 'returns a forbidden response' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when invalid form_field_id is provided' do
      let(:params) do
        {
          form_response_id: form_response.id,
          form_field_value: {
            form_field_id: -1,
            value: 'Test value'
          }
        }
      end

      it 'returns a not found response' do
        action
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when invalid form_response_id is provided' do
      let(:params) do
        {
          form_response_id: 0,
          form_field_value: {
            form_field_id: form_field.id,
            value: 'Test value'
          }
        }
      end

      it 'returns a not found response' do
        action
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when missing value parameter' do
      let(:params) do
        {
          form_response_id: form_response.id,
          nothing: {}
        }
      end

      it 'raises a parameter missing error' do
        expect { action }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end
end
