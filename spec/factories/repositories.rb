# frozen_string_literal: true

FactoryBot.define do
  factory :repository do
    sequence(:name) { |n| "My repository-#{n}" }
    created_by { create :user }
    team
  end
end
