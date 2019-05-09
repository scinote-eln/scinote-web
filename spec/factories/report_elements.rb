# frozen_string_literal: true

FactoryBot.define do
  factory :report_element do
    report
    position { 1 }
    trait :with_experiment do
      type_of { :experiment }
      experiment
    end
  end
end
