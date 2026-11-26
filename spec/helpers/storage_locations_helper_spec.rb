# frozen_string_literal: true

require 'rails_helper'

describe StorageLocationsHelper, type: :helper do
  describe '#storage_locations_placeholder' do
    it 'returns nil when storage locations are enabled' do
      allow(StorageLocation).to receive(:storage_locations_enabled?).and_return(true)

      expect(helper.storage_locations_placeholder).to be_nil
    end

    it 'returns the disabled notice when storage locations are disabled' do
      allow(StorageLocation).to receive(:storage_locations_enabled?).and_return(false)

      result = helper.storage_locations_placeholder

      expect(result).to include I18n.t('storage_locations.storage_locations_disabled')
      expect(result).to include 'bg-sn-super-light-blue'
    end
  end
end
