# frozen_string_literal: true

class AssetPreviewChannel < ApplicationCable::Channel
  include Canaid::Helpers::PermissionsHelper

  def subscribed
    asset = Asset.find_by(id: params[:asset_id])
    return reject unless asset && can_read_asset?(current_user, asset)

    stream_for asset

    transmit({ status: asset.preview_status })
  end

  def unsubscribed
    stop_all_streams
  end
end
