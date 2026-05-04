# frozen_string_literal: true

class CalendarEvent < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :team
  belongs_to :created_by, class_name: 'User'
  has_many :calendar_event_participants, inverse_of: :calendar_event, dependent: :destroy
  has_many :users, through: :calendar_event_participants

  enum event_type: {
    equipment_booking: 0
  }

  scope :repository_rows_filter, ->(subject_ids) { where(subject_type: 'RepositoryRow', subject_id: subject_ids) }
  scope :repository_filter, ->(repository_id) { joins("INNER JOIN repository_rows ON repository_rows.id = calendar_events.subject_id AND calendar_events.subject_type = 'RepositoryRow'").where(repository_rows: { repository_id: repository_id }) }
  scope :datetime_filter, ->(start_time, end_time) { where('start_at <= ? AND end_at >= ?', end_time, start_time) }
  scope :assigned_users_filter, ->(user_ids) { where(id: CalendarEventParticipant.where(user_id: user_ids).select(:calendar_event_id)) }
  scope :event_sub_type_filter, ->(sub_types) { where(event_sub_type: sub_types) }

  before_save :set_full_day

  accepts_nested_attributes_for :calendar_event_participants, allow_destroy: true

  private

  def set_full_day
    if full_day
      self.start_at = start_at.beginning_of_day
      self.end_at = end_at.end_of_day
    end
  end
end
