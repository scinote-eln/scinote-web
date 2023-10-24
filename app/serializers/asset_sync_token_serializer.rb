# frozen_string_literal: true

class AssetSyncTokenSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :url, :asset_id, :filename, :token, :asset_id, :version_token, :checksum

  def checksum
    object.asset.file.checksum
  end

  def url
    asset_sync_download_url(asset_id: object.asset)
  end

  def filename
    object.asset.file.filename
  end
end
