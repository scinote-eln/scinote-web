# frozen_string_literal: true

class StorageLocationsController < ApplicationController
  before_action :load_storage_location, only: %i(update destroy duplicate move)
  before_action :check_read_permissions, only: :index
  before_action :check_manage_permissions, except: :index
  before_action :set_breadcrumbs_items, only: :index

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
      render json: { errors: @storage_location.errors.full_messages }, status: :unprocessable_entity
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
    records = StorageLocation.inner_storage_locations(current_team)
                             .order(:name)
                             .select(:id, :name, :parent_id, :container)
    render json: storage_locations_recursive_builder(nil, records)
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
    render_403 unless true
  end

  def check_manage_permissions
    render_403 unless true
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
    if params[:parent_id]
      location = current_team.storage_locations.find_by(id: params[:parent_id])
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

  def storage_locations_recursive_builder(parent_storage_location, records)
    records.where(parent: parent_storage_location, container: false).map do |storage_location|
      {
        storage_location: storage_location,
        children: storage_locations_recursive_builder(storage_location, records)
      }
    end
  end
end
