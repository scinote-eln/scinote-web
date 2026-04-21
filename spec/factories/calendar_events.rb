# frozen_string_literal: true

FactoryBot.define do
  factory :calendar_event do
    team
    event_type { Faker::Name.unique.name }
    association :created_by, factory: :user
    association :subject, factory: :repository_row
  end
end
