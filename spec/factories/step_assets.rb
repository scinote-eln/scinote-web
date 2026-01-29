# frozen_string_literal: true

FactoryBot.define do
  factory :step_asset do
    transient do
      team { step.team }
    end

    step
    asset { association :asset, team: team }
  end
end
