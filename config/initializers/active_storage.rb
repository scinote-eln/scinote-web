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

Rails.application.config.active_storage.variant_processor = ENV['ACTIVESTORAGE_ENABLE_VIPS'] == 'true' ? :vips : :mini_magick

if Rails.application.config.active_storage.service == 'amazon' &&
   (Rails.configuration.x.fips_mode || ENV['S3_SHA256_CHECKSUMS'] == 'true')
  ActiveSupport::Reloader.to_prepare do
    ActiveStorage::Blob.redefine_method :compute_checksum_in_chunks do |io|
      OpenSSL::Digest.new('SHA256').tap do |checksum|
        while (chunk = io.read(5.megabytes))
          checksum << chunk
        end

        io.rewind
      end.base64digest
    end

    ActiveStorage::Downloader.redefine_method :verify_integrity_of do |file, checksum:|
      unless OpenSSL::Digest::SHA256.file(file).base64digest == checksum
        raise ActiveStorage::IntegrityError
      end
    end
  end
end
