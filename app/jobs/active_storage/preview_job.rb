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

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)
    preview = blob.representation(resize_to_limit: Constants::MEDIUM_PIC_FORMAT).processed
    Rails.logger.info "Preview for the Blod with id: #{blob.id} - successfully generated.\n" \
                      "Transformations applied: #{preview.variation.transformations}"

    preview = blob.representation(resize_to_limit: Constants::LARGE_PIC_FORMAT).processed
    Rails.logger.info "Preview for the Blod with id: #{blob.id} - successfully generated.\n" \
                      "Transformations applied: #{preview.variation.transformations}"

    blob.attachments.take.record.update(file_processing: false)
  end
end
