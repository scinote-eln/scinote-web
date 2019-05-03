# frozen_string_literal: true

module Api
  module V1
    class RepositoryAssetValueSerializer < ActiveModel::Serializer
      attributes :file_id, :file_name, :file_size, :url

      def file_id
        object.asset&.id
      end

      def file_name
        object.asset&.file_file_name
      end

      def file_size
        object.asset&.file_file_size
      end

      def url
        if !object.asset&.file&.exists?
          nil
        elsif object.asset&.file&.is_stored_on_s3?
          object.asset.presigned_url(download: true)
        else
          object.asset.file.url
        end
      end
    end
  end
end
