# frozen_string_literal: true

FactoryBot.define do
  factory :result_asset do
    transient do
      team { result.team }
    end

    asset { association :asset, team: team }
    result
  end
end
