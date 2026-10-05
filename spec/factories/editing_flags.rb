# frozen_string_literal: true

FactoryBot.define do
  factory :editing_flag do
    association :user
    association :subject, factory: :step_text
    timeout_at { EditingFlag::DEFAULT_DURATION.from_now }
  end
end
