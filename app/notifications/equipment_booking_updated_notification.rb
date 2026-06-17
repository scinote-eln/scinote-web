# frozen_string_literal: true

class EquipmentBookingUpdatedNotification < BaseNotification
  def self.subtype
    :equipment_booking_updated
  end

  def title
    I18n.t(
      'notifications.content.equipment_booking_updated.message_html',
      event_name: subject.name,
      repository_row_name: subject.subject.name
    )
  end

  def subject
    CalendarEvent.find(params[:calendar_event_id])
  end
end
