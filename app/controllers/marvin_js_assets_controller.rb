# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  def create
    new_asset = MarvinJsAsset.add_sketch(marvin_params,current_team)
    render json: new_asset
  end

  def destroy
    sketch=MarvinJsAsset.find(params[:id])
    sketch.destroy
    render json: sketch
  end

  private

  def marvin_params
    params.permit(:description, :object_id, :object_type, :name)
  end

end
