# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryAssetValueSerializer < RepositoryBaseValueSerializer
    include Rails.application.routes.url_helpers

    def value
      asset = object.asset
      {
        id: asset.id,
        url: rails_blob_path(asset.file, disposition: 'attachment'),
        preview_url: asset_file_preview_path(asset),
        file_name: asset.file_name,
        icon_html: FileIconsHelper.file_extension_icon_html(asset)
      }
    end
  end
end
