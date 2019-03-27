# frozen_string_literal: true

FactoryBot.define do
  factory :checklist do
    name { Faker::Name.unique.name }
    step
  end
end
