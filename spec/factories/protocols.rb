# frozen_string_literal: true

FactoryBot.define do
  factory :protocol do
    name { Faker::Name.unique.name }
    team
    my_module
  end
end
