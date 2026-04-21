# frozen_string_literal: true

FactoryBot.define do
  factory :calendar_event_participant do
    user
    calendar_event
  end
end
