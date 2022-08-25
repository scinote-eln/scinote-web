# frozen_string_literal: true

module Api
  module V1
    class ProtocolSerializer < ActiveModel::Serializer
      include ApplicationHelper
      include ActionView::Helpers::TextHelper
      include InputSanitizeHelper

      type :protocols
      attributes :id, :name, :authors, :description, :protocol_type
      has_many :protocol_keywords,
               key: :keywords,
               serializer: ProtocolKeywordSerializer,
               class_name: 'ProtocolKeyword',
               unless: -> { object.protocol_keywords.blank? }
      has_many :steps, serializer: StepSerializer, if: -> { object.steps.any? }
      belongs_to :parent, serializer: ProtocolSerializer, if: -> { object.parent.present? }
      has_many :linked_my_modules,
               key: :linked_tasks,
               serializer: TaskSerializer,
               class_name: 'MyModule',
               if: -> { object.in_repository_published? }

      include TimestampableModel

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
