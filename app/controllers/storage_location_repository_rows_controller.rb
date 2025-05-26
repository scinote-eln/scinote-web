# frozen_string_literal: true

class StorageLocationRepositoryRowsController < ApplicationController
  before_action :check_storage_locations_enabled, except: :destroy
  before_action :load_storage_location_repository_row, only: %i(update destroy move)
  before_action :load_storage_location
  before_action :load_repository_row, only: %i(create update destroy move)
  before_action :check_read_permissions, except: %i(create actions_toolbar)
  before_action :check_manage_permissions, only: %i(create update destroy move)

  def index
    storage_location_repository_row = Lists::StorageLocationRepositoryRowsService.new(
      current_team, params
    ).call
    render json: storage_location_repository_row,
           each_serializer: Lists::StorageLocationRepositoryRowSerializer,
           meta: (pagination_dict(storage_location_repository_row) unless @storage_location.with_grid?)
  end

  def create
    ActiveRecord::Base.transaction do
      storage_location_repository_rows = []

      if @storage_location.with_grid?
        params[:positions].each do |position|
          if position.dig(2, :occupied)
            occupied_storage_location_repository_row = @storage_location.storage_location_repository_rows.find_by(id: position.dig(2, :id))
            raise ActiveRecord::RecordInvalid, occupied_row unless discard_storage_location_repository_rows(occupied_storage_location_repository_row)
          end
          storage_location_repository_row = StorageLocationRepositoryRow.new(
            repository_row: @repository_row,
            container_storage_location: @storage_location,
            metadata: { position: position[0..1] },
            created_by: current_user
          )
          storage_location_repository_row.with_lock do
            storage_location_repository_row.save!
            storage_location_repository_rows << storage_location_repository_row
          end
        end
      else
        storage_location_repository_row = StorageLocationRepositoryRow.new(
          repository_row: @repository_row,
          container_storage_location: @storage_location,
          created_by: current_user
        )
        storage_location_repository_row.with_lock do
          storage_location_repository_row.save!
          storage_location_repository_rows << storage_location_repository_row
        end
      end

      log_activity(:storage_location_repository_row_created, {
                     repository_row: @repository_row.id,
                     position: storage_location_repository_rows.map(&:human_readable_position).join(', ')
                   })

      render json: storage_location_repository_rows, each_serializer: Lists::StorageLocationRepositoryRowSerializer
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def update
    ActiveRecord::Base.transaction do
      @storage_location_repository_row.update(storage_location_repository_row_params)

      if @storage_location_repository_row.save
        log_activity(:storage_location_repository_row_moved, {
                       repository_row: @storage_location_repository_row.repository_row_id,
                       position: @storage_location_repository_row.human_readable_position
                     })
        render json: @storage_location_repository_row,
               serializer: Lists::StorageLocationRepositoryRowSerializer
      else
        render json: { errors: @storage_location_repository_row.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def move
    ActiveRecord::Base.transaction do
      @original_storage_location = @storage_location_repository_row.storage_location
      @original_position = @storage_location_repository_row.human_readable_position

      @storage_location_repository_row.discard

      metadata = if @storage_location.with_grid?
                   { position: params[:positions][0][0..1] } # For now, we only support moving one row at a time
                 else
                   {}
                 end

      @storage_location_repository_row = StorageLocationRepositoryRow.create!(
        repository_row: @repository_row,
        storage_location: @storage_location,
        metadata: metadata,
        created_by: current_user
      )
      log_activity(
        :storage_location_repository_row_moved,
        {
          storage_location_original: @original_storage_location.id,
          position_original: @original_position,
          repository_row: @storage_location_repository_row.repository_row_id,
          position: @storage_location_repository_row.human_readable_position
        }
      )
      render json: @storage_location_repository_row,
             serializer: Lists::StorageLocationRepositoryRowSerializer
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if discard_storage_location_repository_rows(@storage_location_repository_row)
        render json: {}
      else
        render json: { errors: @storage_location_repository_row.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def actions_toolbar
    render json: {
      actions: Toolbars::StorageLocationRepositoryRowsService.new(
        current_user,
        items_ids: JSON.parse(params[:items]).pluck('id')
      ).actions
    }
  end

  private

  def discard_storage_location_repository_rows(storage_location_repository_row)
    if storage_location_repository_row.discard
      log_activity(:storage_location_repository_row_deleted, {
                     repository_row: storage_location_repository_row.repository_row_id,
                     position: storage_location_repository_row.human_readable_position
                   })
      return true
    end

    false
  end

  def check_storage_locations_enabled
    render_403 unless StorageLocation.storage_locations_enabled?
  end

  def load_storage_location_repository_row
    @storage_location_repository_row = StorageLocationRepositoryRow.find(
      storage_location_repository_row_params[:id]
    )
    render_404 unless @storage_location_repository_row
  end

  def load_storage_location
    @storage_location = StorageLocation.find(
      storage_location_repository_row_params[:storage_location_id]
    )
    render_404 unless can_read_storage_location?(@storage_location)
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
    render_403 unless can_read_storage_location?(@storage_location)
  end

  def check_manage_permissions
    render_403 unless can_manage_storage_location_repository_rows?(@storage_location)
  end

  def log_activity(type_of, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: @storage_location.team,
            subject: @storage_location,
            message_items: {
              storage_location: @storage_location.id,
              user: current_user.id
            }.merge(message_items))
  end
end
