# frozen_string_literal: true

module ActiveStorage
  module Representations
    class RedirectController < CustomBaseController
      include ActiveStorage::SetBlob
      include ActiveStorage::CheckBlobPermissions

      rescue_from ActiveRecord::RecordNotFound do |e|
        Rails.logger.error(e.message)
        render json: {}, status: :not_found
      end

      def show
        return render plain: '', status: :accepted if @blob.attachments.take.record_type == 'Asset' && !inline_previewable_image? && !preview_ready?

        expires_in ActiveStorage.service_urls_expire_in
        redirect_to @blob.representation(params[:variation_key]).processed.url(disposition: params[:disposition]),
                    allow_other_host: true
      end

      private

      def inline_previewable_image?
        @blob.content_type.match?(%r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES)}}) && @blob.byte_size <= Constants::INLINE_PREVIEW_MAX_FILE_SIZE
      end

      def preview_ready?
        processing = @blob.attachments.take.record.file_processing
        return false if processing

        preview_exists =
          if @blob.variable?
            rep_key = @blob.representation(params['variation_key']).key
            rep_key && @blob.service.exist?(rep_key)
          else
            @blob.preview(params['variation_key']).image.attached?
          end

        return true if preview_exists

        unless processing
          ActiveStorage::PreviewJob.perform_later(@blob.id)
          ActiveRecord::Base.no_touching do
            @blob.attachments.take.record.update(file_processing: true)
          end
        end

        false
      end
    end
  end
end
