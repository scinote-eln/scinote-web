# frozen_string_literal: true

FactoryBot.define do
  factory :result do
    name { Faker::Name.unique.name }
    my_module
    user
  end
end
