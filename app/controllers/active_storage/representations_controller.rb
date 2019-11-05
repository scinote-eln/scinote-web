# frozen_string_literal: true

module ActiveStorage
  class RepresentationsController < CustomBaseController
    include ActiveStorage::SetBlob
    include ActiveStorage::CheckBlobPermissions

    def show
      if @blob.attachments.take.record_type == 'Asset'
        return render plain: '', status: :accepted unless preview_ready?
      end

      expires_in ActiveStorage.service_urls_expire_in
      redirect_to @blob.representation(params[:variation_key]).processed.service_url(disposition: params[:disposition])
    end

    private

    def preview_ready?
      processing = @blob.attachments.take.record.file_processing
      return false if processing

      preview_exists =
        if @blob.variable?
          @blob.service.exist?(@blob.representation(params['variation_key']).key)
        else
          @blob.preview(params['variation_key']).image.attached?
        end

      return true if preview_exists

      unless processing
        ActiveStorage::PreviewJob.perform_later(@blob.id)
        @blob.attachments.take.record.update(file_processing: true)
      end

      false
    end
  end
end
