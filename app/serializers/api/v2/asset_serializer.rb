# frozen_string_literal: true

module Api
  module V2
    class AssetSerializer < ActiveModel::Serializer
      type :attachments

      attributes :id, :file_name, :file_size, :file_type, :file_url, :archived, :locked

      include TimestampableModel

      def file_type
        object.content_type
      end

      def locked
        if object.step
          object.step.attachments_locked || object.step.locked
        elsif object.result
          object.result.attachments_locked
        else
          false
        end
      end

      def file_url
        if object.file&.attached?
          Rails.application.routes.url_helpers.rails_blob_path(object.file, disposition: 'attachment')
        end
      end
    end
  end
end
