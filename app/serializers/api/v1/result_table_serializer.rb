# frozen_string_literal: true

module Api
  module V1
    class ResultTableSerializer < ActiveModel::Serializer
      type :result_tables
      attributes :table_id, :table_contents

      def table_id
        object.table&.id
      end

      def table_contents
        object.table&.contents&.force_encoding(Encoding::UTF_8)
      end
    end
  end
end
