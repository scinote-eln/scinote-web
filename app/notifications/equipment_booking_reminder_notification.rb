# frozen_string_literal: true

class EquipmentBookingReminderNotification < BaseNotification
  def self.subtype
    :equipment_booking_reminder
  end

  def title
    I18n.t(
      'notifications.content.equipment_booking_reminder.message_html',
      event_name: subject.name,
      repository_row_name: subject.subject.name
    )
  end

  def subject
    CalendarEvent.find(params[:calendar_event_id])
  end

  after_deliver do
    CalendarEvent.find(params[:calendar_event_id]).update_column(:reminder_sent, true)
  end
end
