# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  def create
    new_asset = MarvinJsAsset.add_sketch(marvin_params,current_team)
    if new_asset.object_type == 'Step'
      render json: {
          html: render_to_string(
            partial: 'assets/marvinjs/marvin_sketch_card.html.erb',
               locals: { sketch: new_asset, i:0, assets_count: 0, step: new_asset.object}
          )
      }
    elsif new_asset.object_type == 'TinyMceAsset'
      tiny_img = TinyMceAsset.find(new_asset.object_id)
      render json: {
        image: {
          url: view_context.image_url(tiny_img.url(:large)),
          token: Base62.encode(tiny_img.id)
        }
      }, content_type: 'text/html'
    else
      render json: new_asset
    end
  end

  def destroy
    sketch=MarvinJsAsset.find(params[:id])
    sketch.destroy
    render json: sketch
  end

  def update
    sketch=MarvinJsAsset.find(params[:id])
    sketch.update(marvin_params)
    render json: sketch
  end

  private

  def marvin_params
    params.permit(:description, :object_id, :object_type, :name, :image)
  end

end
