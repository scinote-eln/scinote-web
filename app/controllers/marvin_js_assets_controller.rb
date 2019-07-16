# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  before_action :load_vars

  before_action :check_read_permission
  before_action :check_edit_permission, only: %i(update create)

  def show
    asset = current_team.tiny_mce_assets.find_by_id(params[:id]) if marvin_params[:object_type] == 'TinyMceAsset'
    return render_404 unless asset

    render json: {
      name: asset.image.metadata[:name],
      description: asset.image.metadata[:description]
    }
  end

  def create
    result = MarvinJsService.create_sketch(marvin_params, current_user)
    if result[:asset] && marvin_params[:object_type] == 'Step'
      render json: {
        html: render_to_string(
          partial: 'steps/attachments/item.html.erb',
             locals: { asset: result[:asset],
                       i: 0,
                       assets_count: 0,
                       step: result[:object],
                       order_atoz: 0,
                       order_ztoa: 0 }
        )
      }
    elsif result[:asset] && marvin_params[:object_type] == 'Result'
      @my_module = result[:object].my_module
      render json: {
        html: render_to_string(
          partial: 'my_modules/result.html.erb',
            locals: { result: result[:object] }
        )
      }, status: :ok
    elsif result[:asset] && marvin_params[:object_type] == 'TinyMceAsset'
      render json: {
        image: {
          url: rails_representation_url(result[:asset].preview),
          token: Base62.encode(result[:asset].id),
          source_id: result[:asset].id,
          source_type: result[:asset].image.metadata[:asset_type]
        }
      }, content_type: 'text/html'
    elsif result[:asset]
      render json: result[:asset]
    else
      render json: result[:asset].errors, status: :unprocessable_entity
    end
  end

  def update
    asset = MarvinJsService.update_sketch(marvin_params, current_user)
    if asset && marvin_params[:object_type] == 'TinyMceAsset'
      render json: { url: rails_representation_url(asset.preview), id: asset.id }
    elsif asset
      render json: { url: rails_representation_url(asset.medium_preview), id: asset.id, file_name: asset.file_name }
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
  end

  private

  def load_vars
    @asset = if marvin_params[:object_type] == 'TinyMceAsset'
               current_team.tiny_mce_assets.find_by_id(params[:id])
             else
               current_team.assets.find_by_id(params[:id])
             end
    if action_name == 'create'
      return true if marvin_params[:object_type] == 'TinyMceAsset'

      @assoc ||= Step.find_by_id(marvin_params[:object_id]) if marvin_params[:object_type] == 'Step'
      @assoc ||= MyModule.find_by_id(params[:object_id]) if marvin_params[:object_type] == 'Result'
    else
      return render_404 unless @asset

      if marvin_params[:object_type] == 'TinyMceAsset'
        @assoc ||= @asset.object
      else
        @assoc ||= @asset.step
        @assoc ||= @asset.result
      end
    end

    if @assoc.class == Step
      @protocol = @assoc.protocol
    elsif @assoc.class == Protocol
      @protocol = @assoc
    elsif @assoc.class == MyModule
      @my_module = @assoc
    elsif @assoc.class == Result
      @my_module = @assoc.my_module
    end
  end

  def check_read_permission
    if @assoc.class == Step || @assoc.class == Protocol
      render_403 && return unless can_read_protocol_in_module?(@protocol) ||
                                  can_read_protocol_in_repository?(@protocol)
    elsif @assoc.class == Result || @assoc.class == MyModule
      render_403 and return unless can_read_experiment?(@my_module.experiment)
    end
  end

  def check_edit_permission
    if @assoc.class == Step || @assoc.class == Protocol
      render_403 && return unless can_manage_protocol_in_module?(@protocol) ||
                                  can_manage_protocol_in_repository?(@protocol)
    elsif @assoc.class == Result || @assoc.class == MyModule
      render_403 and return unless can_manage_module?(@my_module)
    end
  end

  def marvin_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end
end
