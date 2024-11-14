# frozen_string_literal: true

class PdfPreviewService
  def initialize(blob, attached)
    @blob = blob
    @attached = attached
  end

  def generate!
    preview_file = nil

    @blob.open(tmpdir: tempdir) do |input|
      work_dir = File.dirname(input.path)
      preview_filename = "#{File.basename(input.path, '.*')}.pdf"
      preview_file = File.join(work_dir, preview_filename)
      Rails.logger.info "Starting preparing document preview for file #{@blob.filename.sanitized}..."

      ActiveRecord::Base.transaction do
        success = system(
          'timeout',
          Constants::PREVIEW_TIMEOUT_SECONDS.to_s,
          libreoffice_path,
          '--headless',
          '--invisible',
          '--convert-to',
          'pdf', '--outdir',
          work_dir, input.path
        )
        unless success && File.file?(preview_file)
          raise StandardError, "There was an error generating PDF preview, blob id: #{@blob.id}"
        end

        ActiveRecord::Base.no_touching do
          @attached.attach(io: File.open(preview_file), filename: "#{@blob.filename.base}.pdf")
        end
        Rails.logger.info("Finished preparing PDF preview for file #{@blob.filename.sanitized}.")
      end
    end
  ensure
    File.delete(preview_file) if File.file?(preview_file)
  end

  private

  def tempdir
    Rails.root.join('tmp')
  end

  def libreoffice_path
    ENV['LIBREOFFICE_PATH'] || 'soffice'
  end
end
