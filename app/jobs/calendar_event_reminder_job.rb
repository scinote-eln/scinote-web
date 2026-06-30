# frozen_string_literal: true

class CalendarEventReminderJob < ApplicationJob
  REMINDER_WINDOW = 24.hours
  # Buffer covers missed runs up to 2x the default scheduler interval
  BUFFER = 2.hours

  queue_as :default

  def perform
    NewRelic::Agent.ignore_transaction

    now = DateTime.current
    CalendarEvent
      .where(event_type: :equipment_booking, reminder_sent: false)
      .where('COALESCE(start_datetime, start_date) > ?', now - BUFFER)
      .where('COALESCE(start_datetime, start_date) <= ?', now + REMINDER_WINDOW)
      .find_each do |event|
        # we need to store some params in case of deleted events
        EquipmentBookingReminderNotification.send_notifications(
          {
            calendar_event_id: event.id,
            name: event.name,
            start_date: event.start_date,
            start_datetime: event.start_datetime,
            repository_row_id: event.subject_id
          }
        )
      end
  end
end
