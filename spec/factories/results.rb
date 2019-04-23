# frozen_string_literal: true

FactoryBot.define do
  factory :result do
    name { Faker::Name.unique.name }
    user
    my_module
  end
end
