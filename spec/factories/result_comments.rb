# frozen_string_literal: true

FactoryBot.define do
  factory :result_comment do
    user
    result
    message { Faker::Lorem.sentence }
  end
end
