# frozen_string_literal: true

class StorageLocationRepositoryRowsController < ApplicationController
  before_action :load_storage_location_repository_row, only: %i(update destroy)
  before_action :load_storage_location
  before_action :load_repository_row
  before_action :check_read_permissions, only: :index
  before_action :check_manage_permissions, except: :index

  def index
    storage_location_repository_row = Lists::StorageLocationRepositoryRowsService.new(
      current_team, storage_location_repository_row_params
    ).call
    render json: storage_location_repository_row,
           each_serializer: Lists::StorageLocationRepositoryRowSerializer,
           include: %i(repository_row)
  end

  def update
    @storage_location_repository_row.update(storage_location_repository_row_params)

    if @storage_location_repository_row.save
      render json: {}
    else
      render json: @storage_location_repository_row.errors, status: :unprocessable_entity
    end
  end

  def create
    @storage_location_repository_row = StorageLocationRepositoryRow.new(
      repository_row: @repository_row,
      storage_location: @storage_location,
      metadata: storage_location_repository_row_params[:metadata],
      created_by: current_user
    )

    if @storage_location_repository_row.save
      render json: {}
    else
      render json: @storage_location_repository_row.errors, status: :unprocessable_entity
    end
  end

  def destroy
    if @storage_location_repository_row.discard
      render json: {}
    else
      render json: { errors: @storage_location_repository_row.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def load_storage_location_repository_row
    @storage_location_repository_row = StorageLocationRepositoryRow.find(
      storage_location_repository_row_params[:storage_location_id]
    )
    render_404 unless @storage_location_repository_row
  end

  def load_storage_location
    @storage_location = StorageLocation.where(team: current_team).find(
      storage_location_repository_row_params[:storage_location_id]
    )
    render_404 unless @storage_location
  end

  def load_repository_row
    @repository_row = RepositoryRow.find(storage_location_repository_row_params[:repository_row_id])
    render_404 unless @repository_row
  end

  def storage_location_repository_row_params
    params.permit(:id, :storage_location_id, :repository_row_id,
                  metadata: { position: [] })
  end

  def check_read_permissions
    render_403 unless true
  end

  def check_manage_permissions
    render_403 unless true
  end
end
