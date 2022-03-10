# frozen_string_literal: true

FactoryBot.define do
  factory :my_module do
    transient do
      user { create :user }
    end
    sequence(:name) { |n| "Task-#{n}" }
    sequence(:y) { |n| n }
    sequence(:x) { |n| n }
    workflow_order { MyModule.where(experiment_id: experiment.id).count + 1 }
    experiment
    created_by { experiment.created_by }
    my_module_group { create :my_module_group, experiment: experiment }
    trait :with_tag do
      tags { create_list :tag, 3, project: experiment.project }
    end
    trait :with_due_date do
      due_date { Faker::Time.between(from: Date.today, to: Date.today + 10.days) }
    end
    trait :with_status do
      my_module_status
    end
    trait :archived do
      archived { true }
      archived_on { Time.zone.now }
      archived_by { create(:user) }
    end
  end
end
