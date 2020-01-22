# frozen_string_literal: true

FactoryBot.define do
  factory :repository_asset_value do
    created_by { create :user }
    last_modified_by { created_by }
    asset
    after(:build) do |repository_asset_value|
      repository_asset_value.repository_cell ||= build(:repository_cell,
                                                       :asset_value,
                                                       repository_asset_value: repository_asset_value)
    end
  end
end
