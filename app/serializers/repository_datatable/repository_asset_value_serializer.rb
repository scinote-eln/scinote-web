# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryAssetValueSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :value, :value_type

    def value
      asset = object.repository_asset_value.asset
      {
        id: asset.id,
        url: rails_blob_path(asset.file, disposition: 'attachment'),
        preview_url: asset_file_preview_path(asset),
        file_name: asset.file_name
      }
    end
  end
end
