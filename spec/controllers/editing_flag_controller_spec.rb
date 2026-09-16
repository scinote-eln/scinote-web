# frozen_string_literal: true

require 'rails_helper'

describe EditingFlagController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let(:step) { create :step }

  describe 'POST create' do
    let(:params) { { subject_type: 'Step', subject_id: step.id } }
    let(:action) { post :create, params: params, format: :json }

    it 'creates a new editing flag for the current user and subject' do
      expect { action }.to change(EditingFlag, :count).by(1)
      expect(response).to have_http_status(:success)

      editing_flag = EditingFlag.last
      expect(editing_flag.user).to eq(user)
      expect(editing_flag.subject).to eq(step)
    end

    it 'does not create a duplicate flag for the same user and subject' do
      action
      expect { action }.not_to change(EditingFlag, :count)
    end

    it 'returns not found for an invalid subject_type' do
      post :create, params: { subject_type: 'NotARealModel', subject_id: step.id }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found when the subject does not exist' do
      post :create, params: { subject_type: 'Step', subject_id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET index' do
    let!(:editing_flag) { create :editing_flag, user: user, subject: step, timeout_at: 1.minute.from_now }
    let!(:other_editing_flag) { create :editing_flag, subject: step, timeout_at: 1.minute.from_now }
    let!(:expired_editing_flag) { create :editing_flag, subject: step, timeout_at: 1.minute.ago }

    it 'returns all active editing flags for the given subject' do
      get :index, params: { subject_type: 'Step', subject_id: step.id }, format: :json
      expect(response).to have_http_status(:success)

      response_body = JSON.parse(response.body)
      expect(response_body['data'].length).to eq(2)
      expect(response_body['data'].map { |flag| flag['id'].to_i }).to contain_exactly(editing_flag.id, other_editing_flag.id)
    end
  end

  describe 'PATCH refresh' do
    let!(:editing_flag) { create :editing_flag, user: user, subject: step, timeout_at: 1.minute.from_now }

    it 'extends the timeout_at of the editing flag' do
      patch :refresh, params: { id: editing_flag.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(editing_flag.reload.timeout_at).to be_within(1.second).of(EditingFlag::DEFAULT_DURATION.from_now)
    end

    it 'returns forbidden when the flag belongs to another user' do
      other_flag = create :editing_flag, subject: step, timeout_at: 1.minute.from_now
      patch :refresh, params: { id: other_flag.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for a non-existing id' do
      patch :refresh, params: { id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE destroy' do
    let!(:editing_flag) { create :editing_flag, user: user, subject: step, timeout_at: 1.minute.from_now }

    it 'destroys the editing flag' do
      expect { delete :destroy, params: { id: editing_flag.id }, format: :json }.to change(EditingFlag, :count).by(-1)
      expect(response).to have_http_status(:success)
    end

    it 'returns forbidden when the flag belongs to another user' do
      other_flag = create :editing_flag, subject: step, timeout_at: 1.minute.from_now
      delete :destroy, params: { id: other_flag.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for a non-existing id' do
      delete :destroy, params: { id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
