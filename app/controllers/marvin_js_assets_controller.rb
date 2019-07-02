# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  def create
    new_asset = MarvinJsService.create_sketch(marvin_params, current_user)
    if marvin_params[:object_type] == 'Step'
      render json: {
        html: render_to_string(
          partial: 'steps/attachments/item.html.erb',
             locals: { asset: new_asset, i: 0, assets_count: 0, step: new_asset.step, order_atoz: 0, order_ztoa: 0 }
        )
      }
    #  elsif new_asset.object_type == 'TinyMceAsset'
    #    tiny_img = TinyMceAsset.find(new_asset.object_id)
    #    render json: {
    #      image: {
    #        url: view_context.image_url(tiny_img.url(:large)),
    #        token: Base62.encode(tiny_img.id),
    #        source_id: new_asset.id,
    #        source_type: new_asset.class.name
    #      }
    #    }, content_type: 'text/html'
    elsif new_asset
      render json: new_asset
    else
      render json: new_asset.errors, status: :unprocessable_entity
    end
  end

  def destroy
    asset = current_team.marvin_js_assets.find_by_id(params[:id])
    if asset.destroy
      render json: { id: asset.id }
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
  end

  def update
    asset = MarvinJsService.update_sketch(marvin_params, current_user)
    if asset
      render json: { url: asset.url, id: asset.id }
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
  end

  private

  def marvin_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end
end
