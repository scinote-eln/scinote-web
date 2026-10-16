# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  include MarvinJsActions
  include ActiveStorage::SetCurrent

  before_action :load_vars, except: :create
  before_action :load_create_vars, only: :create
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, except: :create

  def create
    asset = MarvinJsService.create_asset_sketch(@assoc, marvin_params, current_user, current_team)
    create_create_marvinjs_activity(asset, current_user)

    render json: {
      html: render_to_string(partial: 'assets/asset',
                             locals: { asset: asset, gallery_view_id: marvin_params[:object_id] })
    }
  end

  def update
    asset = MarvinJsService.update_asset_sketch(@asset, marvin_params, current_user)
    create_edit_marvinjs_activity(asset, current_user, :finish_editing)

    render json: { url: rails_representation_url(asset.medium_preview),
                   id: asset.id,
                   file_name: asset.blob.metadata['name'] }
  end

  def start_editing
    create_edit_marvinjs_activity(@asset, current_user, :start_editing)
  end

  private

  def load_vars
    @asset = current_team.assets.find_by(id: params[:id])
    render_404 unless @asset
  end

  def load_create_vars
    case marvin_params[:object_type]
    when 'Step'
      @assoc = Step.find_by(id: marvin_params[:object_id])
    when 'Result'
      @assoc = Result.find_by(id: marvin_params[:object_id])
    when 'ResultTemplate'
      @assoc = ResultTemplate.find_by(id: marvin_params[:object_id])
    else
      render_404
    end
  end

  def check_create_permissions
    case @assoc
    when Step
      render_403 unless can_manage_step_attachments?(@assoc)
    when ResultBase
      render_403 unless can_manage_result_attachments?(@assoc)
    else
      render_403
    end
  end

  def check_manage_permissions
    render_403 unless can_manage_asset?(@asset)
  end

  def marvin_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end
end
