# frozen_string_literal: true

FactoryBot.define do
  factory :settings do
    type { Faker::Lorem.sentence.split(' ').sample }
    values { { key_of_data: Faker::Lorem.sentence.split(' ').sample } }

    trait :with_load_values_from_env_defined do
      after(:build) do |application_settings|
        application_settings.define_singleton_method(:load_values_from_env) do
          {
            some_key: Faker::Lorem.sentence.split(' ').sample
          }
        end
      end
    end
  end
end
