# frozen_string_literal: true

require 'active_storage/previewer/libreoffice_previewer'
require 'active_storage/analyzer/custom_image_analyzer'
require 'active_storage/downloader'

Rails.application.config.active_storage.previewers = [ActiveStorage::Previewer::PopplerPDFPreviewer,
                                                      ActiveStorage::Previewer::LibreofficePreviewer]

Rails.application.config.active_storage.analyzers.prepend(ActiveStorage::Analyzer::CustomImageAnalyzer)

Rails.application.config.active_storage.variable_content_types << 'image/svg+xml'

Rails.application.config.active_storage.variant_processor = :vips if ENV['ACTIVESTORAGE_ENABLE_VIPS'] == 'true'

ActiveStorage::Downloader.class_eval do
  def open(key, checksum:, name: 'ActiveStorage-', tmpdir: nil)
    open_tempfile(name, tmpdir) do |file|
      download key, file
      if checksum == 'dummy' || checksum.nil?
        ActiveStorage::Blob.find_by(key: key).update(checksum: Digest::MD5.file(file).base64digest)
      else
        verify_integrity_of file, checksum: checksum
      end
      yield file
    end
  end
end
