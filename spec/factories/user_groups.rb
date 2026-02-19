# frozen_string_literal: true

FactoryBot.define do
  factory :user_group do
    name { Faker::Name.unique.name }
    association :team
    association :created_by, factory: :user
    association :last_modified_by, factory: :user
  end
end
