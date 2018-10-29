# frozen_string_literal: true

FactoryBot.define do
  factory :result_asset do
    asset { create(:asset) }
    result { create(:result) }
  end
end
