# frozen_string_literal: true

class CalendarEventSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :created_by_name, :event_type, :start_at, :end_at, :urls, :subject

  def created_by_name
    object.created_by&.full_name
  end

  def subject
    case object.subject
    when RepositoryRow
      RepositoryRowSerializer.new(object.subject)
    end
  end

  def urls
    {
      show_url: calendar_event_path(object),
      update_url: calendar_event_path(object),
      delete_url: calendar_event_path(object),
      calendar_event_participants_url: calendar_event_calendar_event_participants_path(object),
      create_calendar_event_participant_url: calendar_event_calendar_event_participants_path(object)
    }
  end
end
