# frozen_string_literal: true

module Api
  module V2
    class AssetSerializer < ActiveModel::Serializer
      type :attachments

      attributes :id, :file_name, :file_size, :file_type, :file_url

      include TimestampableModel

      def file_type
        object.content_type
      end

      def file_url
        if object.file&.attached?
          Rails.application.routes.url_helpers.rails_blob_path(object.file, disposition: 'attachment')
        end
      end
    end
  end
end
