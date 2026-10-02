require 'rails_helper'

describe ResultElements::TextsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, :record_deletion_enabled, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:result_template) { create :result_template, protocol: protocol, user: user }
  let!(:result_text) { create :result_text, result: result_template  }
  let!(:result_orderable_element) { create :result_orderable_element, result: result_template, orderable: result_text, position: 3}

  describe 'GET show' do
    let(:action) { get :show, params: { result_id: result_template.id, id: result_text.id }, format: :json }

    context 'when user can read the result' do
      it 'returns the flat serialized result text' do
        action
        expect(response).to have_http_status(:ok)

        body = response.parsed_body
        expect(body).not_to have_key('data')
        expect(body['id']).to eq(result_text.id)
        expect(body).to include('text_view', 'updated_at')
        expect(body['text_digest']).to eq(result_text.text_digest)
        expect(body.dig('urls', 'show_url')).to eq(result_text_path(result_template, result_text))
      end

      it 'does not require manage permissions' do
        allow(controller).to receive(:can_manage_result_text?).and_return(false)
        action
        expect(response).to have_http_status(:ok)
      end

      it 'returns the digest of the stored text when it still has a legacy image token' do
        legacy_text = 'Legacy [~tiny_mce_id:999999999] text'
        result_text.update_column(:text, legacy_text)
        action

        expect(response.parsed_body['text_digest']).to eq(Digest::SHA256.hexdigest(legacy_text))
      end
    end

    context 'when user cannot read the result' do
      let(:other_protocol) { create :protocol, :in_repository_draft, added_by: create(:user) }
      let(:other_result_template) { create :result_template, protocol: other_protocol, user: other_protocol.added_by }
      let(:other_result_text) { create :result_text, result: other_result_template }

      it 'returns forbidden' do
        get :show, params: { result_id: other_result_template.id, id: other_result_text.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST create' do
    it 'creates a new result element text' do
      expect {
        post :create, params: { result_id: result_template.id }
      }.to change(ResultText, :count).by(1)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PUT update' do
    it 'updates an existing result element text' do
      put :update, params: { result_id: result_template.id,
                             id: result_text.id,
                             text_component: { text: 'Updated Text', name: 'Updated Name' } }

      expect(response).to have_http_status(:success)
      result_text.reload
      expect(result_text.text).to eq('Updated Text')
      expect(result_text.name).to eq('Updated Name')
    end

    it 'updates the text when the base digest matches the saved version' do
      put :update, params: { result_id: result_template.id,
                             id: result_text.id,
                             text_component: { text: 'Updated Text' },
                             base_text_digest: result_text.text_digest }

      expect(response).to have_http_status(:success)
      expect(result_text.reload.text).to eq('Updated Text')
      expect(response.parsed_body.dig('data', 'attributes', 'text_digest')).to eq(Digest::SHA256.hexdigest('Updated Text'))
    end

    it 'records who saved the text and returns it with the time' do
      put :update, params: { result_id: result_template.id,
                             id: result_text.id,
                             text_component: { text: 'Updated Text' } }

      expect(result_text.reload.last_modified_by).to eq(user)
      attributes = response.parsed_body.dig('data', 'attributes')
      expect(attributes['last_modified_by']).to eq(user.full_name)
      expect(attributes['last_modified_on']).to eq(I18n.l(result_text.updated_at, format: :full))
    end

    it 'updates only the name when no base digest is sent' do
      original_text = result_text.text
      put :update, params: { result_id: result_template.id,
                             id: result_text.id,
                             text_component: { name: 'Updated Name' } }

      expect(response).to have_http_status(:success)
      result_text.reload
      expect(result_text.name).to eq('Updated Name')
      expect(result_text.text).to eq(original_text)
    end

    it 'accepts the digest of a stored text that still has a legacy image token' do
      legacy_text = 'Legacy [~tiny_mce_id:999999999] text'
      result_text.update_column(:text, legacy_text)
      put :update, params: { result_id: result_template.id,
                             id: result_text.id,
                             text_component: { text: 'Updated Text' },
                             base_text_digest: Digest::SHA256.hexdigest(legacy_text) }

      expect(response).to have_http_status(:success)
      expect(result_text.reload.text).to eq('Updated Text')
    end

    context 'when the text was saved by someone else after the base version' do
      let!(:stale_digest) { result_text.text_digest }

      before { result_text.update!(text: 'Text saved by another user') }

      it 'returns conflict with the latest version and does not save' do
        allow(Activities::CreateActivityService).to receive(:call)
        allow(TinyMceAsset).to receive(:update_images)
        put :update, params: { result_id: result_template.id,
                               id: result_text.id,
                               text_component: { text: 'Updated Text' },
                               base_text_digest: stale_digest }

        expect(response).to have_http_status(:conflict)
        expect(result_text.reload.text).to eq('Text saved by another user')

        latest = response.parsed_body['latest']
        expect(latest['id']).to eq(result_text.id)
        expect(latest['text_digest']).to eq(result_text.text_digest)
        expect(latest).to include('text', 'text_view', 'name', 'updated_at', 'urls')
        expect(Activities::CreateActivityService).not_to have_received(:call)
        expect(TinyMceAsset).not_to have_received(:update_images)
      end

      it 'saves over it when the base digest is blank' do
        put :update, params: { result_id: result_template.id,
                               id: result_text.id,
                               text_component: { text: 'Updated Text' },
                               base_text_digest: '' }

        expect(response).to have_http_status(:success)
        expect(result_text.reload.text).to eq('Updated Text')
      end

      it 'returns forbidden without the latest version when the user cannot manage the text' do
        allow(controller).to receive(:can_manage_result_text?).and_return(false)
        put :update, params: { result_id: result_template.id,
                               id: result_text.id,
                               text_component: { text: 'Updated Text' },
                               base_text_digest: stale_digest }, format: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).not_to have_key('latest')
        expect(result_text.reload.text).to eq('Text saved by another user')
      end
    end
  end

  describe 'POST move' do
    let!(:target_result) { create :result_template, protocol: protocol, user: user }
    it 'moves an existing result element text to another result' do
      post :move, params: { result_id: result_template.id,
                            id: result_text.id,
                            target_id: target_result.id }

      expect(response).to have_http_status(:success)
      result_text.reload
      expect(result_text.result).to eq(target_result)
    end
  end

  describe 'POST duplicate' do
    it 'duplicates an existing result element text' do
      expect {
        post :duplicate, params: { result_id: result_template.id,
                                  id: result_text.id }
      }.to change(ResultText, :count).by(1)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'DELETE destroy' do
    it 'deletes an existing result element text' do
      expect {
        delete :destroy, params: { result_id: result_template.id,
                                   id: result_text.id }
      }.to change(ResultText, :count).by(-1)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST lock' do
    let(:action) { post :lock, params: { result_id: result_template.id, id: result_text.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_lock_result_text?).and_return(true) }

      it 'locks the result text' do
        action
        expect(response).to have_http_status(:ok)
        expect(result_text.reload.locked).to be true
      end

      it 'logs a lock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'lock_result_template_text')))
        action
      end

      it 'does not log an activity when the text is already locked' do
        result_text.update!(locked: true)
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService).not_to have_received(:call)
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_lock_result_text?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST unlock' do
    before { result_text.update!(locked: true) }

    let(:action) { post :unlock, params: { result_id: result_template.id, id: result_text.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_unlock_result_text?).and_return(true) }

      it 'unlocks the result text' do
        action
        expect(response).to have_http_status(:ok)
        expect(result_text.reload.locked).to be false
      end

      it 'logs an unlock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'unlock_result_template_text')))
        action
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_unlock_result_text?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

end
