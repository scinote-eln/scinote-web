# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryAssetValueSerializer < RepositoryBaseValueSerializer
    include Rails.application.routes.url_helpers
    include InputSanitizeHelper

    def value
      asset = value_object.asset
      {
        id: asset.id,
        url: rails_blob_path(asset.file, disposition: 'attachment'),
        preview_url: asset_file_preview_path(asset),
        file_name: escape_input(asset.file_name),
        icon_html: FileIconsHelper.sn_icon_for(asset)
      }
    rescue StandardError => e
      Rails.logger.error e.message
    end
  end
end
