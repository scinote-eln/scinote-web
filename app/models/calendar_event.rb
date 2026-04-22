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
