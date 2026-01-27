# frozen_string_literal: true

module Api
  module V1
    module BlobCreation
      extend ActiveSupport::Concern

      private

      def attach_blob!(record, existing_asset = nil)
        asset = existing_asset || record.assets.new(team: @team)

        record.transaction do
          blob =
            if asset_params[:file]
              blob_from_multipart_formdata
            elsif asset_params[:signed_blob_id]
              asset_params[:signed_blob_id]
            else
              blob_from_api_data
            end

          asset.save!(context: :on_api_upload) if asset.new_record?
          asset.attach_file_version(blob)
          asset.post_process_file
        end

        asset.reload
      end

      def blob_from_multipart_formdata
        ActiveStorage::Blob.create_and_upload!(
          io: asset_params[:file],
          filename: asset_params[:file].original_filename,
          content_type: asset_params[:file].content_type,
          metadata: { created_by_id: current_user.id }
        )
      end

      def blob_from_api_data
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(Base64.decode64(asset_params[:file_data])),
          filename: asset_params[:file_name],
          content_type: asset_params[:file_type],
          metadata: { created_by_id: current_user.id }
        )
      end
    end
  end
end
