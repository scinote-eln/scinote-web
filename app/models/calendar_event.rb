# frozen_string_literal: true

class CalendarEvent < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :team
  belongs_to :created_by, class_name: 'User'
  has_many :calendar_event_participants, inverse_of: :calendar_event, dependent: :destroy
  has_many :users, through: :calendar_event_participants, dependent: :destroy

  before_save :reset_reminder_sent, if: -> { start_date_changed? || start_datetime_changed? }

  enum :event_type, { equipment_booking: 0 }

  scope :repository_rows_filter, ->(subject_ids) { where(subject_type: 'RepositoryRow', subject_id: subject_ids) }
  scope :repository_filter, ->(repository_id) {
    joins("INNER JOIN repository_rows ON
      repository_rows.id = calendar_events.subject_id AND
      calendar_events.subject_type = 'RepositoryRow' AND
      repository_rows.archived = false")
      .where(repository_rows: { repository_id: repository_id })
  }
  scope :datetime_filter, ->(start_time, end_time) {
    where('(start_datetime <= :end_time AND end_datetime >= :start_time) OR
           (start_date <= :end_time AND end_date >= :start_time)',
           start_time: start_time, end_time: end_time)
  }
  scope :assigned_users_filter, ->(user_ids) { where(id: CalendarEventParticipant.where(user_id: user_ids).select(:calendar_event_id)) }
  scope :event_sub_type_filter, ->(sub_types) { where(event_sub_type: sub_types) }

  private

  def reset_reminder_sent
    self.reminder_sent = false
  end
end
