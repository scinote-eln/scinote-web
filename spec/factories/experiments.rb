# frozen_string_literal: true

FactoryBot.define do
  factory :experiment, class: Experiment do
    transient do
      user { create :user }
    end
    sequence(:name) { |n| "Experiment-#{n}" }
    description { Faker::Lorem.sentence }
    last_modified_by { user }
    project { create :project, created_by: user }
    created_by { project.created_by }
    trait :with_tasks do
      after(:create) do |e|
        create_list :my_module, 3, :with_tag, experiment: e, created_by: e.created_by
      end
    end

    trait :archived do
      archived { true }
      archived_on { Time.zone.now }
      archived_by { created_by }
    end
  end
end
