# frozen_string_literal: true

# Provides asynchronous generation of image previews for ActiveStorage::Blob records.
class ActiveStorage::PreviewJob < ActiveStorage::BaseJob
  include ActiveStorageHelper

  queue_as :assets

  discard_on StandardError do |job, error|
    blob = ActiveStorage::Blob.find_by(id: job.arguments.first)
    asset = blob&.attachments&.take&.record
    ActiveRecord::Base.no_touching do
      asset&.update!(file_processing: false)
      blob.metadata['preview_failed'] = true
      blob.update_column(:metadata, blob.metadata)
    end
    AssetPreviewChannel.broadcast_to(asset, status: 'failed')
    Rails.logger.error "Couldn't generate preview for Blob with id: #{job.arguments.first}. Error:\n #{error}"
  end

  discard_on ActiveRecord::RecordNotFound

  retry_on ActiveStorage::IntegrityError, attempts: 3, wait: :polynomially_longer

  def perform(blob_id)
    ActiveRecord::Base.no_touching do
      blob = ActiveStorage::Blob.find(blob_id)
      asset = blob.attachments.take.record
      preview = asset.medium_preview.processed
      Rails.logger.info "Preview for the Blob with id: #{blob.id} - successfully generated.\n" \
                        "Transformations applied: #{preview.variation.transformations}"

      preview = asset.large_preview.processed
      Rails.logger.info "Preview for the Blob with id: #{blob.id} - successfully generated.\n" \
                        "Transformations applied: #{preview.variation.transformations}"

      # Cleanup successful preview generation on retry
      if blob.metadata['preview_failed']
        blob.metadata.delete('preview_failed')
        blob.update_column(:metadata, blob.metadata)
      end

      asset.update(file_processing: false)
      AssetPreviewChannel.broadcast_to(asset, status: 'ready')
    end
  end
end
