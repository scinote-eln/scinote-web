# frozen_string_literal: true

class Recipients::AssignedCalendarEventRecipients
  def initialize(params)
    @params = params
  end

  def recipients
    calendar_event = CalendarEvent.find(@params[:calendar_event_id])

    case calendar_event.subject
    when RepositoryRow
      User.where(id: calendar_event.users.select(:id))
          .where(id: calendar_event.subject.repository.users_with_permission(RepositoryPermissions::READ).select(:id))
    else
      calendar_event.users
    end
  end
end
