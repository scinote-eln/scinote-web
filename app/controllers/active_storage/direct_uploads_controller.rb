# frozen_string_literal: true

module ActiveStorage
  class DirectUploadsController < CustomBaseController
    before_action :check_file_size, only: :create

    def create
      blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_args)
      render json: direct_upload_json(blob)
    end

    private

    def blob_args
      args = params.require(:blob)
                   .permit(:filename, :byte_size, :checksum, :content_type, metadata: {})
                   .to_h
                   .symbolize_keys
      args[:content_type] = 'application/octet-stream' if args[:content_type].blank?
      args
    end

    def direct_upload_json(blob)
      blob.as_json(root: false, methods: :signed_id)
          .merge(direct_upload: { url: blob.service_url_for_direct_upload,
                                  headers: blob.service_headers_for_direct_upload })
    end

    def check_file_size
      render_403 if blob_args[:byte_size] > Rails.configuration.x.file_max_size_mb.megabytes
    end
  end
end
