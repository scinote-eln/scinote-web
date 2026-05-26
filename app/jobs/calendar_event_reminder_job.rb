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
      .where('start_at > ?', now - BUFFER)
      .where('start_at <= ?', now + REMINDER_WINDOW)
      .find_each do |event|
        EquipmentBookingReminderNotification.send_notifications({ calendar_event_id: event.id })
      end
  end
end
