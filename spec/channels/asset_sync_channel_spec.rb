# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssetSyncChannel, type: :channel do
  let(:user) { create(:user) }
  let(:asset) { create(:asset) }

  # This matches Connection#find_verified_user (env['warden'].user must return the current user)
  let(:warden) { instance_double('Warden::Proxy') }

  # Canaid implements can_*? through method_missing, so any_instance verification
  # (which checks method_defined?) cannot see it.
  def stub_permissions(read: true, open_locally: true)
    without_partial_double_verification do
      allow_any_instance_of(described_class).to receive(:can_read_asset?).and_return(read)
      allow_any_instance_of(described_class).to receive(:can_open_asset_locally?).and_return(open_locally)
    end
  end

  before do
    allow(warden).to receive(:user).and_return(user)

    stub_connection current_user: user, env: { 'warden' => warden }
  end

  context 'when the user can read the asset and SciNote Edit is enabled' do
    before { stub_permissions }

    it 'subscribes and streams for the asset' do
      subscribe(asset_id: asset.id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(asset)
    end

    it 'transmits the current checksum on subscribe' do
      subscribe(asset_id: asset.id)

      expect(transmissions.last['checksum']).to eq(asset.file.checksum)
    end

    it 'receives broadcasts for the subscribed asset' do
      subscribe(asset_id: asset.id)

      expect do
        described_class.broadcast_to(asset, checksum: 'new-checksum')
      end.to have_broadcasted_to(asset).from_channel(described_class).with(checksum: 'new-checksum')
    end

    it 'does not stream for another asset' do
      other_asset = create(:asset)
      subscribe(asset_id: asset.id)

      expect(subscription).not_to have_stream_for(other_asset)
    end

    it 'rejects the subscription when the asset does not exist' do
      subscribe(asset_id: -1)

      expect(subscription).to be_rejected
    end

    it 'rejects the subscription when the asset has no file attached' do
      asset.file.purge

      subscribe(asset_id: asset.id)

      expect(subscription).to be_rejected
    end
  end

  context 'when the user cannot read the asset' do
    before { stub_permissions(read: false) }

    it 'rejects the subscription' do
      subscribe(asset_id: asset.id)

      expect(subscription).to be_rejected
    end
  end

  context 'when SciNote Edit is not enabled' do
    before { stub_permissions(open_locally: false) }

    it 'rejects the subscription' do
      subscribe(asset_id: asset.id)

      expect(subscription).to be_rejected
    end
  end
end
