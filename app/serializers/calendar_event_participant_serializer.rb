# frozen_string_literal: true

class CalendarEventParticipantSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :id, :urls

  has_one :calendar_event, serializer: CalendarEventSerializer
  has_one :user, serializer: UserSerializer

  def urls
    {
      delete_url: calendar_event_calendar_event_participant_path(object.calendar_event, object)
    }
  end
end
