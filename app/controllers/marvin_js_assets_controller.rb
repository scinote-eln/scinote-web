# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  def create
    new_asset = MarvinJsAsset.add_sketch(marvin_params,current_team)
    render json: new_asset
  end

  private

  def marvin_params
    params.permit(:description, :object_id, :object_type)
  end

end
