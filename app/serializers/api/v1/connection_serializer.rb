# frozen_string_literal: true

module Api
  module V1
    class ConnectionSerializer < ActiveModel::Serializer
      type :connections
      attributes :id, :input_id, :output_id
      has_one :input_task, serializer: MyModuleSerializer
      has_one :output_task, serializer: MyModuleSerializer
      def input_task
        MyModule.find(object.input_id)
      end

      def output_task
        MyModule.find(object.output_id)
      end
    end
  end
end
