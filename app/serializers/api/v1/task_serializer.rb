# frozen_string_literal: true

module Api
  module V1
    class TaskSerializer < ActiveModel::Serializer
      type :tasks
      attributes :id, :name, :due_date, :description, :state, :archived
      has_many :output_tasks, key: :outputs,
                            serializer: TaskSerializer,
                            class_name: 'MyModule'
      has_many :input_tasks, key: :inputs,
                             serializer: TaskSerializer,
                             class_name: 'MyModule'

      def output_tasks
        object.my_modules
      end

      def input_tasks
        object.my_module_antecessors
      end
    end
  end
end
