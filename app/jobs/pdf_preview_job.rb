# frozen_string_literal: true

# Provides asynchronous generation of image previews for ActiveStorage::Blob records.
class PdfPreviewJob < ApplicationJob
  queue_as :assets

  discard_on StandardError do |job, error|
    asset = Asset.find_by(id: job.arguments.first)

    if asset
      ActiveRecord::Base.no_touching do
        asset.update(pdf_preview_processing: false)
        blob = asset.blob
        blob.metadata['preview_failed'] = true
        blob.save!
      end
    end

    Rails.logger.error("Couldn't generate PDF preview for Asset with id: #{job.arguments.first}. Error:\n #{error}")
  end

  discard_on ActiveRecord::RecordNotFound

  def perform(asset_id)
    asset = Asset.find(asset_id)

    PdfPreviewService.new(asset.file.blob, asset.file_pdf_preview).generate!
  ensure
    asset.update_column(:pdf_preview_processing, false)
  end
end
