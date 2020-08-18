# frozen_string_literal: true

FactoryBot.define do
  factory :my_module_status do
    name { Faker::Name.unique.name }
    description { Faker::Lorem.sentence }
    color { Faker::Color.hex_color }
    my_module_status_flow
    trait :with_consequence do
      after(:create) do |status|
        create :my_module_status_consequence, my_module_status: status
      end
    end
    trait :with_conditions do
      after(:create) do |status|
        create :my_module_status_condition, my_module_status: status
      end
    end
    trait :with_implications do
      after(:create) do |status|
        create :my_module_status_implication, my_module_status: status
      end
    end
  end
end
