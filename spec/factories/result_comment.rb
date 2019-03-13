# frozen_string_literal: true

FactoryBot.define do
  factory :result_comment do
    user
    message { Faker::Lorem.sentence }
    result { create(:result) }
  end
end
