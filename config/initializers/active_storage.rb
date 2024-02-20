# frozen_string_literal: true

require 'active_storage/previewer/libreoffice_previewer'
require 'active_storage/analyzer/image_analyzer/custom_image_magick'
require 'active_storage/analyzer/text_extraction_analyzer'
require 'active_storage/downloader'

# Enable PDF previews for files
Rails.application.config.x.enable_pdf_previews = ENV['ACTIVESTORAGE_ENABLE_PDF_PREVIEWS'] == 'true'

Rails.application.config.active_storage.previewers = [ActiveStorage::Previewer::PopplerPDFPreviewer,
                                                      ActiveStorage::Previewer::LibreofficePreviewer]

Rails.application.config.active_storage.analyzers.prepend(ActiveStorage::Analyzer::ImageAnalyzer::CustomImageMagick)
Rails.application.config.active_storage.analyzers.append(ActiveStorage::Analyzer::TextExtractionAnalyzer)

Rails.application.config.active_storage.variable_content_types << 'image/svg+xml'

Rails.application.config.active_storage.variant_processor = :vips if ENV['ACTIVESTORAGE_ENABLE_VIPS'] == 'true'

ActiveStorage::Downloader.class_eval do
  def open(key, checksum: nil, verify: true, name: 'ActiveStorage-', tmpdir: nil)
    open_tempfile(name, tmpdir) do |file|
      download key, file
      if checksum == 'dummy' || checksum.nil?
        ActiveStorage::Blob.find_by(key: key).update(checksum: Digest::MD5.file(file).base64digest)
      else
        verify_integrity_of(file, checksum: checksum) if verify
      end
      yield file
    end
  end
end
