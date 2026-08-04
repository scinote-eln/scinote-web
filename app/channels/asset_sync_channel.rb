# frozen_string_literal: true

class AssetSyncChannel < ApplicationCable::Channel
  include Canaid::Helpers::PermissionsHelper

  def subscribed
    asset = Asset.find_by(id: params[:asset_id])

    return reject unless can_manage_asset?(current_user, asset) && can_open_asset_locally?(current_user, asset)

    stream_for asset

    transmit({ checksum: asset.file.checksum })
  end

  def unsubscribed
    stop_all_streams
  end
end
