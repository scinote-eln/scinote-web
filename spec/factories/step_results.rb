# frozen_string_literal: true

FactoryBot.define do
  factory :step_result do
    association :step, factory: :step
    association :result, factory: :result
    association :created_by, factory: :user
  end
end
