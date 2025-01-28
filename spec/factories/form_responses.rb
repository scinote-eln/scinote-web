# frozen_string_literal: true

FactoryBot.define do
  factory :form_response do
    association :form
    association :created_by, factory: :user
    association :step_orderable_element, factory: :step_orderable_element

    status { :pending }

    trait :submitted do
      status { :submitted }
      association :submitted_by, factory: :user
      submitted_at { DateTime.current }
    end
  end
end
