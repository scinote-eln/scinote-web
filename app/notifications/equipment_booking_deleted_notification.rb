# frozen_string_literal: true

class EquipmentBookingDeletedNotification < BaseNotification
  def self.subtype
    :equipment_booking_deleted
  end

  def title
    I18n.t(
      'notifications.content.equipment_booking_deleted.message_html',
      event_name: params[:event_name],
      repository_row_name: params[:repository_row_name]
    )
  end
end
