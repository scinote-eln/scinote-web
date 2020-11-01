# frozen_string_literal: true

FactoryBot.define do
  factory :project_folder do
    sequence(:name) { |n| "My projects folder (#{n})" }
    team { create :team }
  end
end
