# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    association :created_by, factory: :user
    sequence(:name) { |n| "My team-#{n}" }
    description { Faker::Lorem.sentence }
    space_taken { 1048576 }
    without_templates { true }
    without_intro_demo { true }
    trait :with_members do
      users { create_list :user, 3 }
    end
  end
end
