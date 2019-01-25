# frozen_string_literal: true

FactoryBot.define do
  factory :system_notification do
    sequence(:title) { |n| "System notification #{n}" }
    description { Faker::ChuckNorris.fact }
    modal_title { Faker::Name.first_name }
    modal_body { Faker::Lorem.paragraphs(4).map { |pr| "<p>#{pr}</p>" }.join }
    source_created_at { Faker::Time.between(3.days.ago, Date.today) }
    source_id { Faker::Number.between(1, 1000) }
    trait :show_on_login do
      show_on_login { true }
    end
  end
end
