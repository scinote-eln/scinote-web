# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  def show
    asset = current_team.tiny_mce_assets.find_by_id(params[:id]) if params[:object_type] == 'TinyMceAsset'
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
          url: result[:asset].preview,
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
    if asset
      render json: { url: asset.medium_preview, id: asset.id }
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
  end

  private

  def marvin_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end
end
