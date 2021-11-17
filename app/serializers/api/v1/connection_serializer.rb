# frozen_string_literal: true

module Api
  module V1
    class ConnectionSerializer < ActiveModel::Serializer
      type :connections
      attributes :id
      belongs_to :from, key: :input_task,
                        serializer: TaskSerializer,
                        class_name: 'MyModule'
      belongs_to :to, key: :output_task,
                      serializer: TaskSerializer,
                      class_name: 'MyModule'
    end
  end
end
