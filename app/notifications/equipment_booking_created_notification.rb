# frozen_string_literal: true

class EquipmentBookingCreatedNotification < BaseNotification
  def self.subtype
    :equipment_booking_created
  end

  def title
    I18n.t(
      'notifications.content.equipment_booking_created.message_html',
      user_name: params[:user_name],
      event_name: subject.name,
      repository_row_name: subject.subject.name
    )
  end

  def subject
    CalendarEvent.find(params[:calendar_event_id])
  end
end
