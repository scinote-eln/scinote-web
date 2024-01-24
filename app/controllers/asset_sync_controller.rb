# frozen_string_literal: true

class AssetSyncController < ApplicationController
  skip_before_action :authenticate_user!, only: %i(update download)
  skip_before_action :verify_authenticity_token, only: %i(update download)
  before_action :authenticate_asset_sync_token!, only: %i(update download)
  before_action :check_asset_sync

  def show
    asset = Asset.find_by(id: params[:asset_id])

    render_error(:forbidden) and return unless asset && can_manage_asset?(asset)

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
    if @asset_sync_token.conflicts?(request.headers['VersionToken'])
      conflict_response = AssetSyncTokenSerializer.new(conflicting_asset_copy_token).as_json
      error_message = { message: I18n.t('assets.conflict_error', filename: @asset.file.filename) }
      render json: conflict_response.merge(error_message), status: :conflict
      return
    end

    @asset.file.attach(io: request.body, filename: @asset.file.filename)
    @asset.touch

    log_activity

    render json: AssetSyncTokenSerializer.new(@asset_sync_token).as_json
  end

  def api_url
    render plain: Constants::ASSET_SYNC_URL
  end

  def log_activity
    assoc ||= @asset.step
    assoc ||= @asset.result

    case assoc
    when Step
      if assoc.protocol.in_module?
        log_step_activity(
          :edit_task_step_file_locally,
          assoc,
          assoc.my_module.project,
          my_module: assoc.my_module.id,
          file: @asset.file_name,
          user: current_user.id,
          step_position_original: @asset.step.position + 1,
          step: assoc.id
        )
      else
        log_step_activity(
          :edit_protocol_template_file_locally,
          assoc,
          nil,
          {
            file: @asset.file_name,
            user: current_user.id,
            step_position_original: @asset.step.position + 1,
            step: assoc.id
          }
        )
      end
    when Result
      log_result_activity(
        :edit_task_result_file_locally,
        assoc,
        file: @asset.file_name,
        user: current_user.id,
        result: Result.first.id
      )
    end
  end

  private

  def render_error(status, filename = nil, message = nil)
    message ||= if filename.present?
                  I18n.t('assets.default_error_with_filename', filename: filename)
                else
                  I18n.t('assets.default_error')
                end

    render json: { message: message }, status: status
  end

  def conflicting_asset_copy_token
    Asset.transaction do
      new_asset = @asset.dup
      new_asset.save
      new_asset.file.attach(
        io: request.body,
        filename: "#{@asset.file.filename.base} (#{t('general.copy')}).#{@asset.file.filename.extension}"
      )

      case @asset.parent
      when Step
        StepAsset.create!(step: @asset.step, asset: new_asset)
      when Result
        ResultAsset.create!(result: @asset.result, asset: new_asset)
      end

      current_user.asset_sync_tokens.create!(asset_id: new_asset.id)
    end
  end

  def authenticate_asset_sync_token!
    @asset_sync_token = AssetSyncToken.find_by(token: request.headers['Authentication'])

    render_error(:unauthorized) and return unless @asset_sync_token&.token_valid?

    @asset = @asset_sync_token.asset
    @current_user = @asset_sync_token.user

    render_error(:forbidden, @asset.file.filename) and return unless can_manage_asset?(@asset)
  end

  def log_step_activity(type_of, step, project = nil, message_items = {})
    default_items = { step: step.id,
                      step_position: { id: step.id, value_for: 'position_plus_one' } }
    message_items = default_items.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: step.protocol,
            team: step.protocol.team,
            project: project,
            message_items: message_items)
  end

  def log_result_activity(type_of, result, message_items)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: result,
            team: result.my_module.team,
            project: result.my_module.project,
            message_items: {
              result: result.id
            }.merge(message_items))
  end

  def check_asset_sync
    render_404 if ENV['ASSET_SYNC_URL'].blank?
  end
end
