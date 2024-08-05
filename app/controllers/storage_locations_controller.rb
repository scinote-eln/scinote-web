# frozen_string_literal: true

class StorageLocationsController < ApplicationController
  before_action :check_storage_locations_enabled, except: :unassign_rows
  before_action :load_storage_location, only: %i(update destroy duplicate move show available_positions unassign_rows)
  before_action :check_read_permissions, except: %i(index create tree actions_toolbar)
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, only: %i(update destroy duplicate move unassign_rows)
  before_action :set_breadcrumbs_items, only: %i(index show)

  def index
    respond_to do |format|
      format.html
      format.json do
        storage_locations = Lists::StorageLocationsService.new(current_team, params).call
        render json: storage_locations, each_serializer: Lists::StorageLocationSerializer,
               user: current_user, meta: pagination_dict(storage_locations)
      end
    end
  end

  def show; end

  def update
    @storage_location.image.purge if params[:file_name].blank?
    @storage_location.image.attach(params[:signed_blob_id]) if params[:signed_blob_id]
    @storage_location.update(storage_location_params)

    if @storage_location.save
      render json: @storage_location, serializer: Lists::StorageLocationSerializer
    else
      render json: { error: @storage_location.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create
    @storage_location = StorageLocation.new(
      storage_location_params.merge({ team: current_team, created_by: current_user })
    )

    @storage_location.image.attach(params[:signed_blob_id]) if params[:signed_blob_id]

    if @storage_location.save
      render json: @storage_location, serializer: Lists::StorageLocationSerializer
    else
      render json: { error: @storage_location.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @storage_location.discard
      render json: {}
    else
      render json: { error: @storage_location.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def duplicate
    new_storage_location = @storage_location.duplicate!
    if new_storage_location
      render json: new_storage_location, serializer: Lists::StorageLocationSerializer
    else
      render json: { errors: :failed }, status: :unprocessable_entity
    end
  end

  def move
    storage_location_destination =
      if move_params[:destination_storage_location_id] == 'root_storage_location'
        nil
      else
        current_team.storage_locations.find(move_params[:destination_storage_location_id])
      end

    @storage_location.update!(parent: storage_location_destination)

    render json: { message: I18n.t('storage_locations.index.move_modal.success_flash') }
  rescue StandardError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: I18n.t('storage_locations.index.move_modal.error_flash') }, status: :bad_request
  end

  def tree
    records = current_team.storage_locations.where(parent: nil, container: [false, params[:container] == 'true'])
    render json: storage_locations_recursive_builder(records)
  end

  def available_positions
    render json: { positions: @storage_location.available_positions }
  end

  def unassign_rows
    @storage_location.storage_location_repository_rows.where(id: params[:ids]).discard_all

    render json: { status: :ok }
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::StorageLocationsService.new(
          current_user,
          storage_location_ids: JSON.parse(params[:items]).map { |i| i['id'] }
        ).actions
    }
  end

  private

  def check_storage_locations_enabled
    render_403 unless StorageLocation.storage_locations_enabled?
  end

  def storage_location_params
    params.permit(:id, :parent_id, :name, :container, :description,
                  metadata: [:display_type, dimensions: [], parent_coordinations: []])
  end

  def move_params
    params.permit(:id, :destination_storage_location_id)
  end

  def load_storage_location
    @storage_location = current_team.storage_locations.find_by(id: storage_location_params[:id])
    render_404 unless @storage_location
  end

  def check_read_permissions
    if @storage_location.container
      render_403 unless can_read_storage_location_containers?(current_team)
    else
      render_403 unless can_read_storage_locations?(current_team)
    end
  end

  def check_create_permissions
    if storage_location_params[:container]
      render_403 unless can_create_storage_location_containers?(current_team)
    else
      render_403 unless can_create_storage_locations?(current_team)
    end
  end

  def check_manage_permissions
    if @storage_location.container
      render_403 unless can_manage_storage_location_containers?(current_team)
    else
      render_403 unless can_manage_storage_locations?(current_team)
    end
  end

  def set_breadcrumbs_items
    @breadcrumbs_items = []

    @breadcrumbs_items.push({
                              label: t('breadcrumbs.inventories')
                            })

    @breadcrumbs_items.push({
                              label: t('breadcrumbs.locations'),
                              url: storage_locations_path
                            })

    storage_locations = []
    if params[:parent_id] || @storage_location
      location = (current_team.storage_locations.find_by(id: params[:parent_id]) || @storage_location)
      if location
        storage_locations.unshift(breadcrumbs_item(location))
        while location.parent
          location = location.parent
          storage_locations.unshift(breadcrumbs_item(location))
        end
      end
    end
    @breadcrumbs_items += storage_locations
  end

  def breadcrumbs_item(location)
    {
      label: location.name,
      url: storage_locations_path(parent_id: location.id)
    }
  end

  def storage_locations_recursive_builder(storage_locations)
    storage_locations.map do |storage_location|
      {
        storage_location: storage_location,
        children: storage_locations_recursive_builder(
          storage_location.storage_locations.where(container: [false, params[:container] == 'true'])
        )
      }
    end
  end
end
