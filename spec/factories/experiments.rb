# frozen_string_literal: true

FactoryBot.define do
  factory :experiment, class: Experiment do
    transient do
      user { create :user }
    end
    sequence(:name) { |n| "Experiment-#{n}" }
    description { Faker::Lorem.sentence }
    created_by { user }
    last_modified_by { user }
    project { create :project, created_by: user }
    trait :with_tasks do
      after(:create) do |e|
        create_list :my_module, 3, :with_tag, experiment: e
      end
    end
  end
end
