# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssetPreviewChannel, type: :channel do
  let(:user) { create(:user) }
  let(:asset) { create(:asset) }

  # This matches Connection#find_verified_user (env['warden'].user must return the current user)
  let(:warden) { instance_double('Warden::Proxy') }

  before do
    allow(warden).to receive(:user).and_return(user)

    stub_connection current_user: user, env: { 'warden' => warden }
  end

  context 'when the user can read the asset' do
    before do
      # Canaid implements can_*? through method_missing, so any_instance verification
      # (which checks method_defined?) cannot see it.
      without_partial_double_verification do
        allow_any_instance_of(described_class).to receive(:can_read_asset?).and_return(true)
      end
    end

    it 'subscribes and streams for the asset' do
      subscribe(asset_id: asset.id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(asset)
    end

    it 'transmits the current preview status on subscribe' do
      allow_any_instance_of(Asset).to receive(:preview_status).and_return('processing')

      subscribe(asset_id: asset.id)

      expect(transmissions.last['status']).to eq('processing')
    end

    it 'transmits failed on subscribe when the preview failed permanently' do
      allow_any_instance_of(Asset).to receive(:preview_status).and_return('failed')

      subscribe(asset_id: asset.id)

      expect(transmissions.last['status']).to eq('failed')
    end

    it 'transmits ready on subscribe when the preview finished before the client subscribed' do
      allow_any_instance_of(Asset).to receive(:preview_status).and_return('ready')

      subscribe(asset_id: asset.id)

      expect(transmissions.last['status']).to eq('ready')
    end

    it 'receives broadcasts for the subscribed asset' do
      subscribe(asset_id: asset.id)

      expect do
        described_class.broadcast_to(asset, status: 'ready')
      end.to have_broadcasted_to(asset).from_channel(described_class).with(status: 'ready')
    end

    it 'does not receive broadcasts for another asset' do
      other_asset = create(:asset)
      subscribe(asset_id: asset.id)

      expect(subscription).not_to have_stream_for(other_asset)
    end
  end

  context 'when the user cannot read the asset' do
    it 'rejects the subscription' do
      subscribe(asset_id: asset.id)

      expect(subscription).to be_rejected
    end
  end

  context 'when the asset does not exist' do
    it 'rejects the subscription' do
      subscribe(asset_id: -1)

      expect(subscription).to be_rejected
    end
  end
end
