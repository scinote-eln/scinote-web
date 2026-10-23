# frozen_string_literal: true

require 'rails_helper'

describe EquipmentBookingHelper, type: :helper do
  describe '#equipment_booking_placeholder' do
    it 'returns nil when equipment booking is enabled' do
      allow(Repository).to receive(:equipment_booking_enabled?).and_return(true)

      expect(helper.equipment_booking_placeholder).to be_nil
    end

    it 'returns the disabled notice when equipment booking is disabled' do
      allow(Repository).to receive(:equipment_booking_enabled?).and_return(false)

      result = helper.equipment_booking_placeholder

      expect(result).to include I18n.t('equipment_booking.equipment_booking_disabled')
      expect(result).to include 'bg-sn-super-light-blue'
    end
  end
end
