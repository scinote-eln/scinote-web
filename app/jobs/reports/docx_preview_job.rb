# frozen_string_literal: true

# Provides asynchronous generation of image previews for ActiveStorage::Blob records.
module Reports
  class DocxPreviewJob < ApplicationJob
    queue_as :reports

    discard_on StandardError do |job, error|
      Rails.logger.error(
        "Couldn't generate PDF preview for DOCX Report with id: #{job.arguments.first}. Error:\n #{error}"
      )
    end

    discard_on ActiveRecord::RecordNotFound

    def perform(report_id)
      report = Report.find(report_id)
      PdfPreviewService.new(report.docx_file.blob, report.docx_preview_file).generate!
    end
  end
end
