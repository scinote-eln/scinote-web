# frozen_string_literal: true

class Recipients::CalendarEventReminderRecipients
  def initialize(params)
    @params = params
  end

  def recipients
    calendar_event = CalendarEvent.find(@params[:calendar_event_id])

    User.where(id: calendar_event.user_ids + [calendar_event.created_by_id])
  end
end
