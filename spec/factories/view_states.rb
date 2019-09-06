# frozen_string_literal: true

FactoryBot.define do
  factory :view_state do
    state {}
    user
    trait :team do
      viewable { create :team }
    end
  end
end
