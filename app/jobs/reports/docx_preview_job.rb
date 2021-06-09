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
      blob = report.docx_file.blob
      blob.open(tmpdir: tempdir) do |input|
        work_dir = File.dirname(input.path)
        preview_filename = "#{File.basename(input.path, '.*')}.pdf"
        preview_file = File.join(work_dir, preview_filename)
        Rails.logger.info "Starting preparing document preview for file #{blob.filename.sanitized}..."

        ActiveRecord::Base.transaction do
          success = system(
            libreoffice_path, '--headless', '--invisible', '--convert-to', 'pdf', '--outdir', work_dir, input.path
          )
          unless success && File.file?(preview_file)
            raise StandardError, "There was an error generating PDF preview, blob id: #{blob.id}"
          end

          ActiveRecord::Base.no_touching do
            report.docx_preview_file.attach(io: File.open(preview_file), filename: "#{blob.filename.base}.pdf")
          end
          Rails.logger.info("Finished preparing PDF preview for file #{blob.filename.sanitized}.")
        end
      ensure
        File.delete(preview_file) if File.file?(preview_file)
      end
    end

    private

    def tempdir
      Rails.root.join('tmp')
    end

    def libreoffice_path
      ENV['LIBREOFFICE_PATH'] || 'soffice'
    end
  end
end
