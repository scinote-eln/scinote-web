# frozen_string_literal: true

FactoryBot.define do
  factory :step_comment do
    user
    step
    message { Faker::Lorem.sentence }
  end
end
