# frozen_string_literal: true

class AssetSyncTokenSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :url, :asset_id, :filename, :token, :asset_id, :version_token, :checksum

  def checksum
    object.asset.file.checksum
  end

  def url
    object.asset.file.url
  end

  def filename
    object.asset.file.filename
  end
end
