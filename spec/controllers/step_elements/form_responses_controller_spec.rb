# frozen_string_literal: true

require 'rails_helper'

describe StepElements::FormResponsesController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  let!(:form) { create(:form, team: team, created_by: user) }
  let!(:step) { create(:step, protocol: protocol) }
  let!(:protocol) { create(:protocol, added_by: user) }
  let!(:form_response) { create(:form_response, form: form, created_by: user) }
  let!(:step_orderable_element) { create(:step_orderable_element, orderable: form_response) }

  before do
    allow(Form).to(receive(:forms_enabled?)).and_return(true)
  end

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      {
        form_id: form.id,
        step_id: step.id
      }
    end

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_manage_step?).and_return(true) }
      before { allow(controller).to receive(:can_create_protocol_form_responses?).and_return(true) }

      it 'creates a form response successfully' do
        expect { action }.to change(FormResponse, :count).by(1)
        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body.dig('data', 'attributes', 'orderable', 'form', 'id')).to eq form.id
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_manage_step?).and_return(true) }
      before { allow(controller).to receive(:can_create_protocol_form_responses?).and_return(false) }

      it 'returns a forbidden response' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT submit' do
    let(:action) {
      put :submit,
      params: {
        form_id: form.id,
        step_id: step.id,
        id: form_response.id
      },
      format: :json
    }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_submit_form_response?).and_return(true) }

      it 'submits the form response successfully' do
        expect(form_response.status).to eq 'pending'
        action
        expect(response).to have_http_status(:success)
        form_response.reload
        expect(form_response.status).to eq 'submitted'
        expect(form_response.submitted_by).to eq user
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_manage_step?).and_return(true) }
      before { allow(controller).to receive(:can_submit_form_response?).and_return(false) }

      it 'returns a forbidden response' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT reset' do
    let(:action) {
      put :reset,
      params: {
        form_id: form.id,
        step_id: step.id,
        id: form_response.id
      },
      format: :json
    }

    context 'when user has permissions and form is submitted' do
      before do
        allow(controller).to receive(:can_reset_form_response?).and_return(true)
        form_response.update!(status: 'submitted')
      end

      it 'resets the form response successfully' do
        expect { action }.to change(FormResponse.unscoped, :count).by(1)
        expect(response).to have_http_status(:success)
        form_response.reload
        expect(form_response.discarded?).to be true
      end
    end

    context 'when form is not submitted' do
      before do
        allow(controller).to receive(:can_reset_form_response?).and_return(true)
        form_response.update!(status: 'pending')
      end

      it 'raises an error' do
        expect { action }.to raise_error(InvalidStatusError)
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_reset_form_response?).and_return(false) }

      it 'returns a forbidden response' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
