# frozen_string_literal: true

module Api
  module V1
    class TaskGroupSerializer < ActiveModel::Serializer
      type :task_groups
      attributes :id
      has_many :my_modules, key: :tasks,
                            serializer: TaskSerializer,
                            class_name: 'MyModule',
                            unless: -> { object.my_modules.blank? }

      include TimestampableModel
    end
  end
end
