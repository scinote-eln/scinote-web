# frozen_string_literal: true

module Api
  module V1
    class TableSerializer < ActiveModel::Serializer
      type :tables
      attributes :id, :name, :contents, :metadata, :position

      include TimestampableModel

      def contents
        object.contents&.force_encoding(Encoding::UTF_8)
      end

      def position
        object&.step_table&.step_orderable_element&.position
      end
    end
  end
end
