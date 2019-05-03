# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "My project-#{n}" }
    association :created_by, factory: :user
    team { create :team, created_by: created_by }
    #@@@20180925JS - Add RapTaskLevel to the factory for projects
    # rap_task_level { RapTaskLevel.first } # db.seed should be a prereq for this, so do we need the association?
    rap_task_level { RapTaskLevel.first || association(:rap_task_level) }
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
