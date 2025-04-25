# frozen_string_literal: true

FactoryBot.define do
  factory :repository_template do
    association :team
  end
end
