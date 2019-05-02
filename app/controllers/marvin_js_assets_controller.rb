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
    elsif new_asset
      render json: new_asset
    else
      render json: new_asset.errors, status: :unprocessable_entity
    end
  end

  def show
    sketch = current_team.marvin_js_assets.find_by_id(params[:id])
    if sketch
      if sketch.object_type == 'Step'
        editable = can_manage_protocol_in_module?(sketch.object.protocol) ||
                   can_manage_protocol_in_repository?(sketch.object.protocol)
        render json: {
          sketch: sketch,
          editable: editable
        }
      else
        render json: sketch
      end
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
  end

  def destroy
    sketch = current_team.marvin_js_assets.find_by_id(params[:id])
    if sketch.destroy
      render json: sketch
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
  end

  def update
    sketch = MarvinJsAsset.update_sketch(marvin_params, current_team)
    if sketch
      render json: sketch
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
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
