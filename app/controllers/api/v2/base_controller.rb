# frozen_string_literal: true

module Api
  module V2
    class BaseController < Api::V1::BaseController
      private

      def load_result(key = :result_id)
        @result = @task.results.find(params.require(key))

        raise PermissionError.new(Result, :read) unless can_read_result?(@result)
      end

      def load_result_text(key = :result_text_id)
        @result_text = @result.result_texts.find(params.require(key))
        raise PermissionError.new(Result, :read) unless can_read_result?(@result)
      end

      def load_result_table(key = :table_id)
        @table = @result.tables.find(params.require(key))
        raise PermissionError.new(Result, :read) unless can_read_result?(@result)
      end
    end
  end
end
