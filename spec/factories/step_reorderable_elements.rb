# frozen_string_literal: true

FactoryBot.define do
  factory :step_orderable_element do
    orderable { create :step_text, step: step }
    step
    sequence(:position) { |n| n }
  end
end
