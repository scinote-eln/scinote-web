# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    full_name { 'admin' }
    initials { 'AD' }
    sequence(:email) { |n| "user-#{n}@example.com" }
    password { 'asdf1243' }
    password_confirmation { 'asdf1243' }
    current_sign_in_at { DateTime.now }
  end
end
