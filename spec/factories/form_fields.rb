# frozen_string_literal: true

FactoryBot.define do
  factory :form_field do
    name { Faker::Name.unique.name }
    description { Faker::Lorem.sentence }
    sequence(:position) { |n| n - 1 }
    association :created_by, factory: :user
    association :last_modified_by, factory: :user
    association :form
  end
end
