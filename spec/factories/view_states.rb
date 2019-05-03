# frozen_string_literal: true

FactoryBot.define do
  factory :view_state do
    state {}
    user { User.first || create(:user) }
    viewable { Team.first || create(:team) }
  end
end
