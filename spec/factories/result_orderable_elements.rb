# frozen_string_literal: true

FactoryBot.define do
  factory :result_orderable_element do
    result
    sequence(:position) { |n| n }

    trait :result_text do
      after(:build) do |result_orderable_element|
        result_orderable_element.orderable ||= build(:result_text, result: result_orderable_element.result)
      end
    end

    trait :result_table do
      after(:build) do |result_orderable_element|
        result_orderable_element.orderable ||= build(:result_table, result: result_orderable_element.result)
      end
    end
  end
end
