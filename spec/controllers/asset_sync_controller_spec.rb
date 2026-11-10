# frozen_string_literal: true

require 'rails_helper'

describe AssetSyncController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    step: true,
    step_asset: true,
    result_asset: true
  }

  let(:protocol_in_repository) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:step_in_repository) { create :step, protocol: protocol_in_repository, user: user }
  let(:result_template) { create :result_template, protocol: protocol_in_repository, user: user }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSET_SYNC_URL').and_return('http://asset-sync.test')
  end

  def downgrade_to_viewer(assignable)
    UserAssignment.where(user: user, assignable: assignable).update_all(user_role_id: viewer_role.id)
  end

  describe 'GET #show' do
    it 'creates a sync token and returns its data' do
      asset = step_asset.asset
      expect { get :show, params: { asset_id: asset.id } }.to change(AssetSyncToken, :count).by(1)
      expect(response).to have_http_status(:ok)
      token = AssetSyncToken.last
      body = response.parsed_body
      expect(body['token']).to eq token.token
      expect(body['asset_id']).to eq asset.id
      expect(body['filename']).to eq 'test.jpg'
      expect(body['version_token']).to eq token.version_token
      expect(body['checksum']).to eq asset.file.checksum
      expect(body['url']).to include("/asset_sync/#{asset.id}/download")
    end

    it 'reuses a valid token' do
      existing = user.asset_sync_tokens.create!(asset: step_asset.asset)
      expect { get :show, params: { asset_id: step_asset.asset.id } }.not_to change(AssetSyncToken, :count)
      expect(response.parsed_body['token']).to eq existing.token
    end

    it 'creates a new token when existing one expired' do
      expired = user.asset_sync_tokens.create!(asset: step_asset.asset, expires_at: 1.day.ago)
      expect { get :show, params: { asset_id: step_asset.asset.id } }.to change(AssetSyncToken, :count).by(1)
      expect(response.parsed_body['token']).not_to eq expired.token
    end

    it 'is forbidden for viewers' do
      step_asset
      downgrade_to_viewer(my_module)
      expect { get :show, params: { asset_id: step_asset.asset.id } }.not_to change(AssetSyncToken, :count)
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['message']).to eq I18n.t('assets.default_error')
    end

    it 'is forbidden for unknown asset' do
      get :show, params: { asset_id: -1 }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found when asset sync is not configured' do
      allow(ENV).to receive(:[]).with('ASSET_SYNC_URL').and_return(nil)
      get :show, params: { asset_id: step_asset.asset.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #download' do
    # token authentication runs before set_current_team, so permissions rely on the stored current team
    before { user.update!(current_team_id: team.id) }

    it 'redirects to the file url with a valid token' do
      token = user.asset_sync_tokens.create!(asset: step_asset.asset)
      allow_any_instance_of(ActiveStorage::Blob).to receive(:url).and_return('http://files.test/test.jpg')
      request.headers['Authentication'] = token.token
      get :download, params: { asset_id: step_asset.asset.id }
      expect(response).to redirect_to('http://files.test/test.jpg')
    end

    it 'returns unauthorized with invalid token' do
      request.headers['Authentication'] = 'invalid'
      get :download, params: { asset_id: step_asset.asset.id }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized with revoked token' do
      token = user.asset_sync_tokens.create!(asset: step_asset.asset, revoked_at: Time.current)
      request.headers['Authentication'] = token.token
      get :download, params: { asset_id: step_asset.asset.id }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PUT #update' do
    # token authentication runs before set_current_team, so permissions rely on the stored current team
    before { user.update!(current_team_id: team.id) }

    def sync_update(asset, version_token: nil, content: 'updated content')
      token = user.asset_sync_tokens.create!(asset: asset)
      request.headers['Authentication'] = token.token
      request.headers['VersionToken'] = version_token || token.version_token
      put :update, body: content
      token
    end

    it 'uploads a new file version and logs activity for task step' do
      asset = step_asset.asset
      token = nil
      expect { token = sync_update(asset) }.to change(Activity, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(asset.reload.file.download).to eq 'updated content'
      expect(asset.last_modified_by).to eq user
      expect(response.parsed_body['token']).to eq token.token
      expect(Activity.last.type_of).to eq 'edit_task_step_file_locally'
    end

    it 'broadcasts the new checksum to the asset' do
      asset = step_asset.asset
      expect { sync_update(asset) }
        .to have_broadcasted_to(asset)
        .from_channel(AssetSyncChannel)
        .with { |data| expect(data[:checksum]).to eq(asset.reload.file.checksum) }
    end

    it 'returns conflict with updated token data when version token does not match' do
      sync_update(step_asset.asset, version_token: 'outdated')
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body['message']).to eq I18n.t('assets.conflict_error', filename: 'test.jpg')
      expect(step_asset.asset.reload.file.download).to eq 'updated content'
    end

    it 'logs activity for protocol template step' do
      asset = create(:step_asset, step: step_in_repository).asset
      sync_update(asset)
      expect(Activity.last.type_of).to eq 'edit_protocol_template_file_locally'
    end

    it 'logs activity for result' do
      sync_update(result_asset.asset)
      expect(Activity.last.type_of).to eq 'edit_task_result_file_locally'
    end

    it 'logs activity for result template' do
      asset = create(:result_asset, result: result_template, asset: create(:asset, team: team)).asset
      sync_update(asset)
      expect(Activity.last.type_of).to eq 'edit_result_template_file_locally'
    end

    it 'stores office files as wopi contents and bumps version' do
      asset = step_asset.asset
      asset.file.blob.update!(filename: 'document.docx')
      token = nil
      expect { token = sync_update(asset) }.to change { asset.reload.version }.by(1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['token']).to eq token.token
      expect(response.parsed_body['filename']).to eq 'document.docx'
    end

    it 'is forbidden for viewers' do
      step_asset
      downgrade_to_viewer(my_module)
      sync_update(step_asset.asset)
      expect(response).to have_http_status(:forbidden)
      expect(step_asset.asset.reload.file.download).not_to eq 'updated content'
    end
  end

  describe 'GET #api_url' do
    it 'returns configured asset sync url' do
      stub_const('Constants::ASSET_SYNC_URL', 'http://asset-sync.test')
      get :api_url
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq 'http://asset-sync.test'
    end
  end
end
