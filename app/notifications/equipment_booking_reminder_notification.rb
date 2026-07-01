# frozen_string_literal: true

class EquipmentBookingReminderNotification < BaseNotification
  def self.subtype
    :equipment_booking_reminder
  end

  def title
    repository_row_path =
      !subject.subject.is_a?(NonExistantRecord) && # repository_row was not deleted
      repository_path(subject.subject.repository, landing_page: true, row_id: subject.subject.id, anchor: 'schedule-section')

    date_time =
      I18n.l(subject.start_date || subject.start_datetime, format: :full_date)

    date_time += " #{subject.start_datetime&.strftime('%H:%M')}" if subject.start_datetime

    I18n.t(
      'notifications.content.equipment_booking_reminder.message_html',
      event_name: subject.name,
      date_time: date_time,
      repository_row_name:
        repository_row_path ? "<a href=\"#{repository_row_path}\">#{subject.subject.name}</a>" : subject.subject.name
    )
  end

  def subject
    CalendarEvent.find(params[:calendar_event_id])
  rescue ActiveRecord::RecordNotFound
    NonExistantRecord.new(
      params[:name],
      params: {
        start_date: params[:start_date],
        start_datetime: params[:start_datetime],
        subject: RepositoryRow.find_by(id: params[:repository_row_id]) || NonExistantRecord.new(params[:repository_row_name])
      }
    )
  end

  after_deliver do
    CalendarEvent.find(params[:calendar_event_id]).update_column(:reminder_sent, true)
  end
end
