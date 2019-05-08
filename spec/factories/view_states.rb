# frozen_string_literal: true

FactoryBot.define do
  factory :view_state do
    state {}
    user
    viewable { create :team }
  end
end
