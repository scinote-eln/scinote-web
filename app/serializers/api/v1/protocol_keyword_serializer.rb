# frozen_string_literal: true

module Api
  module V1
    class ProtocolKeywordSerializer < ActiveModel::Serializer
      type :protocol_keywords
      attributes :id, :name
    end
  end
end
