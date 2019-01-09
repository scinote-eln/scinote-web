# frozen_string_literal: true

FactoryBot.define do
  factory :my_module do
    sequence(:name) { |n| "Task-#{n}" }
    x { Faker::Number.between(1, 100) }
    y { Faker::Number.between(1, 100) }
    workflow_order { 0 }
    experiment
    my_module_group { create :my_module_group, experiment: experiment }
  end
end
