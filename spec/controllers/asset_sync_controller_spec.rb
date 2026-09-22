# frozen_string_literal: true

require 'rails_helper'

describe AssetSyncController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    team_role: :owner,
    step: true,
    step_asset: true
  }

  let(:asset) { step_asset.asset }
  let(:asset_sync_token) { user.asset_sync_tokens.create!(asset: asset) }

  before do
    stub_const('ENV', ENV.to_h.merge('ASSET_SYNC_URL' => 'http://localhost:9999'))

    # authenticate_asset_sync_token! is a prepend_before_action, so it checks
    # permissions before any team context is set up for the request - permission_team
    # falls back to the user's current team, which real users always have.
    user.update!(current_team_id: team.id)
  end

  describe 'PUT #update' do
    let(:action) do
      request.headers['Authentication'] = asset_sync_token.token
      request.headers['VersionToken'] = asset_sync_token.version_token
      request.env['RAW_POST_DATA'] = 'updated file contents'

      put :update
    end

    it 'broadcasts the new checksum to the asset' do
      expect { action }
        .to have_broadcasted_to(asset)
        .from_channel(AssetSyncChannel)
        .with { |data| expect(data[:checksum]).to eq(asset.reload.file.checksum) }
    end
  end
end
