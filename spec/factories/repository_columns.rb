# frozen_string_literal: true

FactoryBot.define do
  factory :repository_column do
    sequence(:name) { |n| "My column-#{n}" }
    created_by { create :user }
    repository
    data_type :RepositoryTextValue
  end
end
