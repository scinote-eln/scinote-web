# frozen_string_literal: true

# Provides asynchronous generation of image previews for ActiveStorage::Blob records.
class ActiveStorage::PreviewJob < ActiveStorage::BaseJob
  include ActiveStorageHelper

  queue_as :assets

  discard_on StandardError do |job, error|
    blob = ActiveStorage::Blob.find_by(id: job.arguments.first)
    ActiveRecord::Base.no_touching do
      blob&.attachments&.take&.record&.update!(file_processing: false)
      blob.metadata['preview_failed'] = true
      blob.save!
    end
    Rails.logger.error "Couldn't generate preview for Blob with id: #{job.arguments.first}. Error:\n #{error}"
  end

  discard_on ActiveRecord::RecordNotFound

  retry_on ActiveStorage::IntegrityError, attempts: 3, wait: :polynomially_longer

  def perform(blob_id)
    ActiveRecord::Base.no_touching do
      blob = ActiveStorage::Blob.find(blob_id)
      asset = blob.attachments.take.record
      preview = asset.medium_preview.processed
      Rails.logger.info "Preview for the Blod with id: #{blob.id} - successfully generated.\n" \
                        "Transformations applied: #{preview.variation.transformations}"

      preview = asset.large_preview.processed
      Rails.logger.info "Preview for the Blod with id: #{blob.id} - successfully generated.\n" \
                        "Transformations applied: #{preview.variation.transformations}"

      asset.update(file_processing: false)
    end
  end
end
