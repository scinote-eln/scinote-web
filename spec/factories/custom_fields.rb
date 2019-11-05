# frozen_string_literal: true

FactoryBot.define do
  factory :custom_field do
    name { 'My custom field' }
    user
    team
  end
end
