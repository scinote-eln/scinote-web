# frozen_string_literal: true

module Api
  module V1
    class ResultTextSerializer < ActiveModel::Serializer
      type :result_texts
      attributes :text
    end
  end
end
