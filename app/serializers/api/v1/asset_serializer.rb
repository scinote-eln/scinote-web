# frozen_string_literal: true

module Api
  module V1
    class AssetSerializer < ActiveModel::Serializer
      include Rails.application.routes.url_helpers

      type :attachments
      attributes :id, :file_name, :file_size, :file_type, :file_url
      belongs_to :step, serializer: StepSerializer

      def file_type
        object.content_type
      end

      def file_url
        rails_blob_url(object.file, disposition: 'attachment') if object.file.attached?
      end
    end
  end
end
