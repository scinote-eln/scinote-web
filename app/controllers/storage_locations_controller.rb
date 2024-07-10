# frozen_string_literal: true

class StorageLocationsController < ApplicationController
  before_action :load_storage_location, only: %i(update destroy)
  before_action :check_read_permissions, only: :index
  before_action :check_manage_permissions, except: :index

  def index
    storage_locations = Lists::StorageLocationsService.new(current_team, storage_location_params).call
    render json: storage_locations, each_serializer: Lists::StorageLocationSerializer
  end

  def update
    @storage_location.image.attach(storage_location_params[:signed_blob_id]) if storage_location_params[:signed_blob_id]
    @storage_location.update(storage_location_params)

    if @storage_location.save
      render json: {}
    else
      render json: @storage_location.errors, status: :unprocessable_entity
    end
  end

  def create
    @storage_location = StorageLocation.new(
      storage_location_params.merge({ team: current_team, created_by: current_user })
    )

    @storage_location.image.attach(storage_location_params[:signed_blob_id]) if storage_location_params[:signed_blob_id]

    if @storage_location.save
      render json: {}
    else
      render json: @storage_location.errors, status: :unprocessable_entity
    end
  end

  def destroy
    if @storage_location.discard
      render json: {}
    else
      render json: { errors: @storage_location.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def storage_location_params
    params.permit(:id, :parent_id, :name, :container, :signed_blob_id, :description,
                  metadata: { dimensions: [], parent_coordinations: [], display_type: :string })
  end

  def load_storage_location
    @storage_location = StorageLocation.where(team: current_team).find(storage_location_params[:id])
    render_404 unless @storage_location
  end

  def check_read_permissions
    render_403 unless true
  end

  def check_manage_permissions
    render_403 unless true
  end
end
