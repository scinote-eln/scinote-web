# frozen_string_literal: true

FactoryBot.define do
  factory :user_group_membership do
    association :user
    association :user_group
    association :created_by
  end
end
