# frozen_string_literal: true

FactoryBot.define do
  factory :user_project do
    user
    project
    assigned_by { user }
  end
end
