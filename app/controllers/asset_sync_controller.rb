# frozen_string_literal: true

class AssetSyncController < ApplicationController
  skip_before_action :authenticate_user!, only: %i(update download)
  skip_before_action :verify_authenticity_token, only: %i(update download)
  before_action :authenticate_asset_sync_token!, only: %i(update download)

  def show
    asset = Asset.find_by(id: params[:asset_id])

    head :forbidden unless asset && can_manage_asset?(asset)

    asset_sync_token = current_user.asset_sync_tokens.find_or_create_by(asset_id: params[:asset_id])

    unless asset_sync_token.token_valid?
      asset_sync_token = current_user.asset_sync_tokens.create(asset_id: params[:asset_id])
    end

    render json: AssetSyncTokenSerializer.new(asset_sync_token).as_json
  end

  def download
    redirect_to(@asset.file.url, allow_other_host: true)
  end

  def update
    head(:conflict) and return if @asset_sync_token.conflicts?(request.headers['VersionToken'])

    @asset.file.attach(io: request.body, filename: @asset.file.filename)
    @asset.touch

    render json: AssetSyncTokenSerializer.new(@asset_sync_token).as_json
  end

  # private

  def authenticate_asset_sync_token!
    @asset_sync_token = AssetSyncToken.find_by(token: request.headers['Authentication'])

    head(:unauthorized) and return unless @asset_sync_token&.token_valid?

    @asset = @asset_sync_token.asset
    @current_user = @asset_sync_token.user

    head :forbidden unless can_manage_asset?(@asset)
  end
end
