# frozen_string_literal: true

require 'active_storage/previewer/libreoffice_previewer'

Rails.application.config.active_storage.previewers = [ActiveStorage::Previewer::PopplerPDFPreviewer,
                                                      ActiveStorage::Previewer::LibreofficePreviewer]

Rails.application.config.active_storage.variable_content_types << 'image/svg+xml'

# Rails.application.config.active_storage.variant_processor = :vips
