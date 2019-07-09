# frozen_string_literal: true

module Api
  module V1
    class ResultAssetSerializer < ActiveModel::Serializer
      type :result_files
      attributes :file_id, :file_name, :file_size, :url

      def file_id
        object.asset&.id
      end

      def file_name
        object.asset&.file_name
      end

      def file_size
        object.asset&.file_size
      end

      def url
        if !object.asset&.file&.exists?
          nil
        else
          rails_blob_path(object.asset.file, disposition: 'attachment')
        end
      end
    end
  end
end
