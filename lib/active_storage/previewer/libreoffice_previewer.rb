# frozen_string_literal: true

module ActiveStorage
  class Previewer
    class LibreofficePreviewer < Previewer
      class << self
        require 'active_storage_file_util'
        include ActiveStorageFileUtil

        def accept?(blob)
          previewable_document?(blob)
        end
      end

      def preview(**_options)
        download_blob_to_tempfile do |input|
          work_dir = File.dirname(input.path)
          basename = File.basename(input.path, '.*')
          preview_file = File.join(work_dir, "#{basename}.png")

          Rails.logger.info "Starting preparing document preview for file #{blob.filename.sanitized}..."

          begin
            success = system(
              libreoffice_path, '--headless', '--invisible', '--convert-to', 'png', '--outdir', work_dir, input.path
            )

            unless success && File.file?(preview_file)
              raise StandardError, "There was an error generating document preview, blob id: #{blob.id}"
            end

            yield io: File.open(preview_file), filename: "#{blob.filename.base}.png", content_type: 'image/png'

            Rails.logger.info "Finished preparing document preview for file #{blob.filename.sanitized}."
          ensure
            File.delete(preview_file) if File.file?(preview_file)
          end
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
end
