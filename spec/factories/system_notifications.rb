# frozen_string_literal: true

FactoryBot.define do
  factory :system_notification do
    sequence(:title) { |n| "System notification #{n}" }
    description { Faker::ChuckNorris.fact[0..255] }
    modal_title { Faker::Name.first_name }
    modal_body { Faker::Lorem.paragraphs(number: 4).map { |pr| "<p>#{pr}</p>" }.join }
    source_created_at { Faker::Time.between(from: 3.days.ago, to: Date.today) }
    source_id { SystemNotification.order(source_id: :desc).first&.source_id.to_i + 1 }
    last_time_changed_at { Time.now }
    trait :show_on_login do
      show_on_login { true }
    end
  end
end
