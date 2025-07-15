# frozen_string_literal: true

require 'active_storage/previewer/libreoffice_previewer'
require 'active_storage/analyzer/image_analyzer/custom_image_magick'
require 'active_storage/analyzer/text_extraction_analyzer'

# Enable PDF previews for files
Rails.application.config.x.enable_pdf_previews = ENV['ACTIVESTORAGE_ENABLE_PDF_PREVIEWS'] == 'true'

Rails.application.config.active_storage.previewers << ActiveStorage::Previewer::PopplerPDFPreviewer
Rails.application.config.active_storage.previewers << ActiveStorage::Previewer::LibreofficePreviewer

Rails.application.config.active_storage.analyzers.prepend(ActiveStorage::Analyzer::ImageAnalyzer::CustomImageMagick)
Rails.application.config.active_storage.analyzers.append(ActiveStorage::Analyzer::TextExtractionAnalyzer)

Rails.application.config.active_storage.variable_content_types << 'image/svg+xml'

Rails.application.config.active_storage.variant_processor = :vips if ENV['ACTIVESTORAGE_ENABLE_VIPS'] == 'true'

