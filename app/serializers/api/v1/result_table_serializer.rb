# frozen_string_literal: true

module Api
  module V1
    class ResultTableSerializer < ActiveModel::Serializer
      type :result_tables
      attributes :table_id
    end
  end
end
