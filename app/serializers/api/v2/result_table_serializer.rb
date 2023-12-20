# frozen_string_literal: true

module Api
  module V2
    class ResultTableSerializer < Api::V1::ResultTableSerializer
      type :tables
    end
  end
end
