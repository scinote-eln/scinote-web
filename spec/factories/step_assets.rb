# frozen_string_literal: true

FactoryBot.define do
  factory :step_asset do
    asset { create(:asset) }
    step { create(:step) }
  end
end
