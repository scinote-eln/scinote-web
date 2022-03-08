# frozen_string_literal: true

FactoryBot.define do
  factory :my_module do
    sequence(:name) { |n| "Task-#{n}" }
    x { Faker::Number.between(1, 100) }
    y { Faker::Number.between(1, 100) }
    workflow_order { MyModule.where(experiment_id: experiment.id).count + 1 }
    experiment
    my_module_group { create :my_module_group, experiment: experiment }
    trait :with_tag do
      tags { create_list :tag, 3, project: experiment.project }
    end
    trait :with_due_date do
      due_date { Faker::Time.between(Date.today, Date.today + 10.days) }
    end
  end
end
