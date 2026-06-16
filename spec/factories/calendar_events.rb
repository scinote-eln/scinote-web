# frozen_string_literal: true

FactoryBot.define do
  factory :calendar_event do
    team
    event_type { :equipment_booking }
    start_datetime { DateTime.now }
    end_datetime { DateTime.now + 1.days }
    association :created_by, factory: :user
    association :subject, factory: :repository_row
  end
end
