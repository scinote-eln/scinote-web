# frozen_string_literal: true

module Api
  module V1
    class ActivitySerializer < ActiveModel::Serializer
      type :activities
      attributes :id, :type_of, :message
      belongs_to :project, serializer: ProjectSerializer
      belongs_to :experiment, serializer: ExperimentSerializer,
                              if: -> { object.experiment.present? }
      belongs_to :my_module, key: :task,
                             serializer: TaskSerializer,
                             class_name: 'MyModule',
                             if: -> { object.my_module.present? }
      belongs_to :user, serializer: UserSerializer
    end
  end
end
