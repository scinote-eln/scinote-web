# frozen_string_literal: true

class CalendarEventSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :full_day, :created_by_name, :event_type, :event_sub_type,
             :start_at_string, :end_at_string, :urls, :subject, :start_at_formatted, :end_at_formatted, :users

  def full_day
    object.start_date.present? && object.end_date.present?
  end

  def created_by_name
    object.created_by&.full_name
  end

  def start_at_formatted
    if full_day
      return I18n.l(object.start_date, format: :full_date)
    end
    I18n.l(object.start_datetime, format: :full)
  end

  def end_at_formatted
    if full_day
      return I18n.l(object.end_date, format: :full_date)
    end
    I18n.l(object.end_datetime, format: :full)
  end

  def start_at_string
    return object.start_date if full_day
    object.start_datetime
  end

  def end_at_string
    return object.end_date if full_day
    object.end_datetime
  end

  def users
    object.users.map do |user|
      {
        id: user.id,
        name: user.full_name
      }
    end
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
