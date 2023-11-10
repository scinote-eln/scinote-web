# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryAssetValueSerializer < RepositoryBaseValueSerializer
    include Rails.application.routes.url_helpers
    include InputSanitizeHelper
    include FileIconsHelper

    def value
      asset = value_object.asset
      {
        id: asset.id,
        url: rails_blob_path(asset.file, disposition: 'attachment'),
        preview_url: asset_file_preview_path(asset),
        file_name: escape_input(asset.file_name),
        icon_html: sn_icon_for(asset),
        medium_preview_url: asset.previewable? && rails_representation_url(asset.medium_preview)
      }
    rescue StandardError => e
      Rails.logger.error e.message
    end
  end
end
