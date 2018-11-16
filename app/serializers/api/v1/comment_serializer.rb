# frozen_string_literal: true

module Api
  module V1
    class CommentSerializer < ActiveModel::Serializer
      type :comments
      attributes :id, :message

      belongs_to :user, serializer: UserSerializer
      belongs_to :project,
                 serializer: ProjectSerializer,
                 if: -> { object.class == ProjectComment &&
                          !instance_options[:hide_project] }
      # TODO
      #belongs_to :my_module,
      #           serializer: TaskSerializer,
      #           key: :task,
      #           class_name: 'MyModule',
      #           if: -> { object.class == TaskComment &&
      #                    !instance_options[:hide_task] }
      #belongs_to :step,
      #           serializer: StepSerializer,
      #           if: -> { object.class == StepComment &&
      #                    !instance_options[:hide_step] }
      belongs_to :result,
                 serializer: ResultSerializer,
                 if: -> { object.class == ResultComment &&
                          !instance_options[:hide_result] }
    end
  end
end
