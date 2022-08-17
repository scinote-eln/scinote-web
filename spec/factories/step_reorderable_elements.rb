# frozen_string_literal: true

FactoryBot.define do
  factory :step_orderable_element do
    orderable { create :step_text, step: step }
    step
    position { step ? step.step_orderable_elements.count : Faker::Number.between(from: 1, to: 10) }
  end
end
