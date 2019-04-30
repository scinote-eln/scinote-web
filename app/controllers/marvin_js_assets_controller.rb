# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  def create
    new_asset = MarvinJsAsset.add_sketch(marvin_params, current_team)
    if new_asset.object_type == 'Step'
      render json: {
        html: render_to_string(
          partial: 'assets/marvinjs/marvin_sketch_card.html.erb',
             locals: { sketch: new_asset, i: 0, assets_count: 0, step: new_asset.object }
        )
      }
    elsif new_asset.object_type == 'TinyMceAsset'
      tiny_img = TinyMceAsset.find(new_asset.object_id)
      render json: {
        image: {
          url: view_context.image_url(tiny_img.url(:large)),
          token: Base62.encode(tiny_img.id),
          source_id: new_asset.id,
          source_type: new_asset.class.name
        }
      }, content_type: 'text/html'
    else
      render json: new_asset
    end
  end

  def show
    render json: (MarvinJsAsset.find_by_id(params[:id]) || {})
  end

  def destroy
    sketch = MarvinJsAsset.find(params[:id])
    sketch.destroy
    render json: sketch
  end

  def update
    render json: MarvinJsAsset.update_sketch(marvin_params)
  end

  def team_sketches
    result = ''
    sketches = current_team.marvin_js_assets.where.not(object_type: 'TinyMceAsset')
    sketches.each do |sketch|
      result += render_to_string(
        partial: 'shared/marvinjs_modal_sketch.html.erb',
           locals: { sketch: sketch }
      )
    end

    render json: { html: result, sketches: sketches.pluck(:id) }
  end

  private

  def marvin_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end
end
