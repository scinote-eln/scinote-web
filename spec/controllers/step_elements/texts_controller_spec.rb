# frozen_string_literal: true

require 'rails_helper'

describe StepElements::TextsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:step) { create :step, protocol: protocol }
  let!(:step_text) { create :step_text, step: step }

  describe 'GET show' do
    let(:action) { get :show, params: { step_id: step.id, id: step_text.id }, format: :json }

    context 'when user can read the protocol' do
      it 'returns the flat serialized step text' do
        action
        expect(response).to have_http_status(:ok)

        body = response.parsed_body
        expect(body).not_to have_key('data')
        expect(body['id']).to eq(step_text.id)
        expect(body).to include('text_view', 'updated_at')
        expect(body['text_digest']).to eq(step_text.text_digest)
        expect(body.dig('urls', 'show_url')).to eq(step_text_path(step, step_text))
      end

      it 'does not require manage permissions' do
        allow(controller).to receive(:can_manage_step_text?).and_return(false)
        action
        expect(response).to have_http_status(:ok)
      end

      it 'returns the digest of the stored text when it still has a legacy image token' do
        legacy_text = 'Legacy [~tiny_mce_id:999999999] text'
        step_text.update_column(:text, legacy_text)
        action

        expect(response.parsed_body['text_digest']).to eq(Digest::SHA256.hexdigest(legacy_text))
      end
    end

    context 'when user cannot read the protocol' do
      let(:other_step) { create :step, protocol: create(:protocol, :in_repository_draft, added_by: create(:user)) }
      let(:other_step_text) { create :step_text, step: other_step }

      it 'returns forbidden' do
        get :show, params: { step_id: other_step.id, id: other_step_text.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT update' do
    let!(:step_text) { create :step_text, step: step, text: 'Original text', name: 'Original name' }
    let(:params) { { step_id: step.id, id: step_text.id, text_component: { text: 'New text' } } }

    before { allow(controller).to receive(:can_manage_step_text?).and_return(true) }

    it 'updates the text when no base digest is sent' do
      put :update, params: params, format: :json

      expect(response).to have_http_status(:ok)
      expect(step_text.reload.text).to eq('New text')
    end

    it 'updates the text when the base digest matches the saved version' do
      put :update, params: params.merge(base_text_digest: step_text.text_digest), format: :json

      expect(response).to have_http_status(:ok)
      expect(step_text.reload.text).to eq('New text')
      expect(response.parsed_body.dig('data', 'attributes', 'text_digest')).to eq(Digest::SHA256.hexdigest('New text'))
    end

    it 'records who saved the text and returns it with the time' do
      put :update, params: params, format: :json

      expect(step_text.reload.last_modified_by).to eq(user)
      attributes = response.parsed_body.dig('data', 'attributes')
      expect(attributes['last_modified_by']).to eq(user.full_name)
      expect(attributes['last_modified_on']).to eq(I18n.l(step_text.updated_at, format: :full))
    end

    it 'updates only the name when no base digest is sent' do
      put :update, params: { step_id: step.id, id: step_text.id, text_component: { name: 'New name' } }, format: :json

      expect(response).to have_http_status(:ok)
      step_text.reload
      expect(step_text.name).to eq('New name')
      expect(step_text.text).to eq('Original text')
    end

    it 'accepts the digest of a stored text that still has a legacy image token' do
      legacy_text = 'Legacy [~tiny_mce_id:999999999] text'
      step_text.update_column(:text, legacy_text)
      put :update, params: params.merge(base_text_digest: Digest::SHA256.hexdigest(legacy_text)), format: :json

      expect(response).to have_http_status(:ok)
      expect(step_text.reload.text).to eq('New text')
    end

    context 'when the text was saved by someone else after the base version' do
      let!(:stale_digest) { step_text.text_digest }

      before { step_text.update!(text: 'Text saved by another user') }

      it 'returns conflict with the latest version and does not save' do
        allow(Activities::CreateActivityService).to receive(:call)
        allow(TinyMceAsset).to receive(:update_images)
        put :update, params: params.merge(base_text_digest: stale_digest), format: :json

        expect(response).to have_http_status(:conflict)
        expect(step_text.reload.text).to eq('Text saved by another user')

        latest = response.parsed_body['latest']
        expect(latest['id']).to eq(step_text.id)
        expect(latest['text_digest']).to eq(step_text.text_digest)
        expect(latest).to include('text', 'text_view', 'name', 'updated_at', 'urls')
        expect(Activities::CreateActivityService).not_to have_received(:call)
        expect(TinyMceAsset).not_to have_received(:update_images)
      end

      it 'saves over it when the base digest is blank' do
        put :update, params: params.merge(base_text_digest: ''), format: :json

        expect(response).to have_http_status(:ok)
        expect(step_text.reload.text).to eq('New text')
      end

      it 'returns forbidden without the latest version when the user cannot manage the text' do
        allow(controller).to receive(:can_manage_step_text?).and_return(false)
        put :update, params: params.merge(base_text_digest: stale_digest), format: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).not_to have_key('latest')
        expect(step_text.reload.text).to eq('Text saved by another user')
      end
    end
  end

  describe 'POST lock' do
    let(:action) { post :lock, params: { step_id: step.id, id: step_text.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_lock_step_text?).and_return(true) }

      it 'locks the step text' do
        action
        expect(response).to have_http_status(:ok)
        expect(step_text.reload.locked).to be true
      end

      it 'logs a lock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'lock_protocol_step_text')))
        action
      end

      it 'does not log an activity when the text is already locked' do
        step_text.update!(locked: true)
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService).not_to have_received(:call)
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_lock_step_text?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST unlock' do
    before { step_text.update!(locked: true) }

    let(:action) { post :unlock, params: { step_id: step.id, id: step_text.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_unlock_step_text?).and_return(true) }

      it 'unlocks the step text' do
        action
        expect(response).to have_http_status(:ok)
        expect(step_text.reload.locked).to be false
      end

      it 'logs an unlock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'unlock_protocol_step_text')))
        action
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_unlock_step_text?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
