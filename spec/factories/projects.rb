# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "My project-#{n}" }
    association :created_by, factory: :user
    team { create :team, created_by: created_by }
    archived { false }
    visibility { 'hidden' }
  end

  factory :project_user, class: User do
    full_name Faker::Name.name
    initials 'AD'
    email Faker::Internet.email
    password 'asdf1243'
    password_confirmation 'asdf1243'
  end
end
