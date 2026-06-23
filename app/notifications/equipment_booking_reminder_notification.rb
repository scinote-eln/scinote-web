# frozen_string_literal: true

class EquipmentBookingReminderNotification < BaseNotification
  def self.subtype
    :equipment_booking_reminder
  end

  def title
    repository_row_path =
      repository_path(subject.subject.repository, landing_page: true, row_id: subject.subject.id, anchor: 'schedule-section')

    date_time =
      I18n.l(subject.start_date || subject.start_datetime, format: :full_date)

    date_time += " #{subject.start_datetime&.strftime('%H:%M')}" if subject.start_datetime

    I18n.t(
      'notifications.content.equipment_booking_reminder.message_html',
      event_name: subject.name,
      date_time: date_time,
      repository_row_name: "<a href=\"#{repository_row_path}\">#{subject.subject.name}</a>"
    )
  end

  def subject
    CalendarEvent.find(params[:calendar_event_id])
  end

  after_deliver do
    CalendarEvent.find(params[:calendar_event_id]).update_column(:reminder_sent, true)
  end
end
