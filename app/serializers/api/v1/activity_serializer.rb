# frozen_string_literal: true

module Api
  module V1
    class ActivitySerializer < ActiveModel::Serializer
      include ActionView::Helpers::TextHelper
      include ApplicationHelper
      include GlobalActivitiesHelper

      def self.serializer_for(model, options)
        return TaskSerializer if model.class == MyModule

        super
      end

      type :activities
      attributes :id, :type_of, :message
      belongs_to :project, serializer: ProjectSerializer
      belongs_to :subject, polymorphic: true
      belongs_to :owner, key: :user, serializer: UserSerializer

      include TimestampableModel

      def message
        if object.old_activity?
          object.message
        else
          generate_activity_content(object, no_links: true)
        end
      end
    end
  end
end
