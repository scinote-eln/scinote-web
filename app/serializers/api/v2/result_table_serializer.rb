# frozen_string_literal: true

module Api
  module V2
    class ResultTableSerializer < ActiveModel::Serializer
      type :tables
      attributes :table_id, :table_contents, :table_metadata

      def table_id
        object.table&.id
      end

      def table_contents
        object.table&.contents&.force_encoding(Encoding::UTF_8)
      end

      def table_metadata
        object.table&.metadata
      end
    end
  end
end
