# frozen_string_literal: true

FactoryBot.define do
  factory :webhook do
    activity_filter
    http_method { 'post' }
    url { 'https://www.example.com' }
  end
end
