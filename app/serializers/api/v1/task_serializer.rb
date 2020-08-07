# frozen_string_literal: true

module Api
  module V1
    class TaskSerializer < ActiveModel::Serializer
      include ApplicationHelper
      include ActionView::Helpers::TextHelper
      include InputSanitizeHelper

      type :tasks
      attributes :id, :name, :started_on, :due_date, :description, :state, :archived
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

      def description
        if instance_options[:rte_rendering]
          custom_auto_link(object.tinymce_render(:description),
                           simple_format: false,
                           tags: %w(img),
                           team: instance_options[:team])
        else
          object.description
        end
      end
    end
  end
end
