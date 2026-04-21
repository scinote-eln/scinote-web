# frozen_string_literal: true

class CalendarEvent < ApplicationRecord
  belongs_to :subject, polymorphic: true
  belongs_to :team
  belongs_to :created_by, class_name: 'User'
  has_many :calendar_event_participants, inverse_of: :calendar_event, dependent: :destroy
  has_many :users, through: :calendar_event_participants
end
