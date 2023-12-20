# frozen_string_literal: true

module Api
  module V2
    class StepTextSerializer < Api::V1::StepTextSerializer
      type :texts
    end
  end
end
