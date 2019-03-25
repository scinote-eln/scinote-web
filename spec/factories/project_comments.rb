# frozen_string_literal: true

FactoryBot.define do
  factory :project_comment do
    user
    project
    message { Faker::Lorem.sentence }
  end
end
