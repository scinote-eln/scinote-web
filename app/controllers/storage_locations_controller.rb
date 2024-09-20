# frozen_string_literal: true

class StorageLocationsController < ApplicationController
  before_action :check_storage_locations_enabled, except: :unassign_rows
  before_action :load_storage_location, only: %i(update destroy duplicate move show available_positions unassign_rows export_container import_container)
  before_action :check_read_permissions, except: %i(index create tree actions_toolbar)
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, only: %i(update destroy duplicate move unassign_rows import_container)
  before_action :set_breadcrumbs_items, only: %i(index show)

  def index
    respond_to do |format|
      format.html do
        if storage_location_params[:parent_id]
          @parent_location = StorageLocation.viewable_by_user(current_user)
                                            .find_by(id: storage_location_params[:parent_id])
        end
      end
      format.json do
        storage_locations = Lists::StorageLocationsService.new(current_user, current_team, params).call
        render json: storage_locations, each_serializer: Lists::StorageLocationSerializer,
               user: current_user, meta: pagination_dict(storage_locations)
      end
    end
  end

  def show; end

  def create
    ActiveRecord::Base.transaction do
      @storage_location = StorageLocation.new(
        storage_location_params.merge({ created_by: current_user })
      )

      @storage_location.team = @storage_location.root_storage_location.team || current_team

      @storage_location.image.attach(params[:signed_blob_id]) if params[:signed_blob_id]

      if @storage_location.save
        log_activity('storage_location_created')
        render json: @storage_location, serializer: Lists::StorageLocationSerializer
      else
        render json: { error: @storage_location.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def update
    ActiveRecord::Base.transaction do
      @storage_location.image.purge if params[:file_name].blank?
      @storage_location.image.attach(params[:signed_blob_id]) if params[:signed_blob_id]
      @storage_location.update(storage_location_params)

      if @storage_location.save
        log_activity('storage_location_edited')
        render json: @storage_location, serializer: Lists::StorageLocationSerializer
      else
        render json: { error: @storage_location.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if @storage_location.discard
        log_activity('storage_location_deleted')
        render json: {}
      else
        render json: { error: @storage_location.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def duplicate
    ActiveRecord::Base.transaction do
      new_storage_location = @storage_location.duplicate!
      if new_storage_location
        @storage_location = new_storage_location
        log_activity('storage_location_created')
        render json: @storage_location, serializer: Lists::StorageLocationSerializer
      else
        render json: { errors: :failed }, status: :unprocessable_entity
      end
    end
  end

  def move
    ActiveRecord::Base.transaction do
      original_storage_location = @storage_location.parent
      destination_storage_location =
        if move_params[:destination_storage_location_id] == 'root_storage_location'
          nil
        else
          current_team.storage_locations.find(move_params[:destination_storage_location_id])
        end

      @storage_location.update!(parent: destination_storage_location)

      log_activity('storage_location_moved', {
                     storage_location_original: original_storage_location&.id, # nil if moved from root
                     storage_location_destination: destination_storage_location&.id # nil if moved to root
                   })
    end

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
    ActiveRecord::Base.transaction do
      @storage_location_repository_rows = @storage_location.storage_location_repository_rows.where(id: params[:ids])
      @storage_location_repository_rows.each(&:discard)
      log_unassign_activities
    end

    render json: { status: :ok }
  end

  def export_container
    xlsx = StorageLocations::ExportService.new(@storage_location, current_user).to_xlsx

    send_data(
      xlsx,
      filename: "#{@storage_location.name.gsub(/\s/, '_')}_export_#{Date.current}.xlsx",
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
  end

  def import_container
    result = StorageLocations::ImportService.new(@storage_location, params[:file], current_user).import_items
    if result[:status] == :ok
      if (result[:assigned_count] + result[:unassigned_count]).positive?
        log_activity(
          :storage_location_imported,
          {
            assigned_count: result[:assigned_count],
            unassigned_count: result[:unassigned_count]
          }
        )
      end

      render json: result
    else
      render json: result, status: :unprocessable_entity
    end
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::StorageLocationsService.new(
          current_user,
          storage_location_ids: JSON.parse(params[:items]).pluck('id')
        ).actions
    }
  end

  private

  def check_storage_locations_enabled
    render_403 unless StorageLocation.storage_locations_enabled?
  end

  def storage_location_params
    params.permit(:id, :parent_id, :name, :container, :description,
                  metadata: [:display_type, { dimensions: [], parent_coordinations: [] }])
  end

  def move_params
    params.permit(:id, :destination_storage_location_id)
  end

  def load_storage_location
    @storage_location = StorageLocation.viewable_by_user(current_user).find_by(id: storage_location_params[:id])
    render_404 unless @storage_location
  end

  def check_read_permissions
    render_403 unless can_read_storage_location?(@storage_location)
  end

  def check_create_permissions
    if storage_location_params[:container]
      render_403 unless can_create_storage_location_containers?(current_team)
    else
      render_403 unless can_create_storage_locations?(current_team)
    end
  end

  def check_manage_permissions
    render_403 unless can_manage_storage_location?(@storage_location)
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

  def log_activity(type_of, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: "#{'container_' if @storage_location.container}#{type_of}",
            owner: current_user,
            team: @storage_location.team,
            subject: @storage_location,
            message_items: {
              storage_location: @storage_location.id,
              user: current_user.id
            }.merge(message_items))
  end

  def log_unassign_activities
    @storage_location_repository_rows.each do |storage_location_repository_row|
      Activities::CreateActivityService
        .call(activity_type: :storage_location_repository_row_deleted,
              owner: current_user,
              team: @storage_location.team,
              subject: storage_location_repository_row.repository_row,
              message_items: {
                storage_location: storage_location_repository_row.storage_location_id,
                repository_row: storage_location_repository_row.repository_row_id,
                position: storage_location_repository_row.human_readable_position,
                user: current_user.id
              })
    end
  end
end
