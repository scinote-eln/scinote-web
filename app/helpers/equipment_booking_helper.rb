# frozen_string_literal: true

module EquipmentBookingHelper
  def equipment_booking_placeholder
    return if Repository.equipment_booking_enabled?

    "<div class=\"p-4 rounded bg-sn-super-light-blue\">
      #{I18n.t('equipment_booking.equipment_booking_disabled')}
    </div>"
  end
end
