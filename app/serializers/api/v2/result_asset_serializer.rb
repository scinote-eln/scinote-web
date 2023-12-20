# frozen_string_literal: true

module Api
  module V2
    class ResultAssetSerializer < Api::V1::ResultAssetSerializer
      type :attachments
      attributes :file_id, :file_name, :file_size, :file_type, :file_url

      def file_type
        object.asset&.content_type
      end

      def file_url
        if object.asset&.file&.attached?
          Rails.application.routes.url_helpers.rails_blob_path(object.asset.file, disposition: 'attachment')
        end
      end
    end
  end
end
