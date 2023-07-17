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
        if @blob.attachments.take.record_type == 'Asset'
          return render plain: '', status: :accepted unless preview_ready?
        end

        expires_in ActiveStorage.service_urls_expire_in
        redirect_to @blob.representation(params[:variation_key]).processed.url(disposition: params[:disposition]),
                    allow_other_host: true
      end

      private

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
