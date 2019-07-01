# frozen_string_literal: true

FactoryBot.define do
  factory :wopi_app do
    sequence(:name) { |n| "WopiApp-#{n}" }
    icon { 'app-icon' }
    wopi_discovery
  end
end
