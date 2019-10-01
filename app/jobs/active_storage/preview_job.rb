# frozen_string_literal: true

# Provides asynchronous generation of image previews for ActiveStorage::Blob records.
class ActiveStorage::PreviewJob < ActiveStorage::BaseJob
  queue_as :assets

  discard_on StandardError do |job, error|
    blob = ActiveStorage::Blob.find_by(id: job.arguments.first)
    blob&.attachments&.take&.record&.update(file_processing: false)
    Rails.logger.error "Couldn't generate preview for Blob with id: #{job.arguments.first}. Error:\n #{error}"
  end

  discard_on ActiveRecord::RecordNotFound

  retry_on ActiveStorage::IntegrityError, attempts: 3, wait: :exponentially_longer

  def perform(blob_id, variation_key)
    blob = ActiveStorage::Blob.find(blob_id)
    preview = blob.representation(variation_key).processed
    blob.attachments.take.record.update(file_processing: false)

    Rails.logger.info "Preview for the Blod with id: #{blob.id} - successfully generated.\n" \
                      "Transformations applied: #{preview.variation.transformations}"
  end
end
