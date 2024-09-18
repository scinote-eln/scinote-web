# frozen_string_literal: true

class TeamSharedObjectsController < ApplicationController
  before_action :load_vars
  before_action :check_sharing_permissions

  def update
    ActiveRecord::Base.transaction do
      @activities_to_log = []

      # Global share
      if @model.globally_shareable?
        permission_level =
          if params[:select_all_teams]
            params[:select_all_write_permission] ? :shared_write : :shared_read
          else
            :not_shared
          end

        @model.permission_level = permission_level

        if @model.permission_level_changed?
          @model.save!
          @model.team_shared_objects.each(&:destroy!) unless permission_level == :not_shared
          case @model
          when Repository
            setup_repository_global_share_activity
          end

          log_activities and next
        end
      end

      # Share to specific teams
      params[:team_share_params].each do |t|
        @model.update!(permission_level: :not_shared) if @model.globally_shareable?

        team_shared_object = @model.team_shared_objects.find_or_initialize_by(team_id: t['id'])

        new_record = team_shared_object.new_record?
        team_shared_object.update!(
          permission_level: t['private_shared_with_write'] ? :shared_write : :shared_read
        )

        setup_team_share_activity(team_shared_object, new_record) if team_shared_object.saved_changes?
      end

      # Unshare
      @model.team_shared_objects.where.not(
        team_id: params[:team_share_params].filter { |t| t['private_shared_with'] }.pluck('id')
      ).each do |team_shared_object|
        team_shared_object.destroy!
        setup_team_share_activity(team_shared_object, false)
      end

      log_activities
    end
  end

  def shareable_teams
    teams = current_user.teams.order(:name) - [@model.team]
    render json: teams, each_serializer: ShareableTeamSerializer, model: @model
  end

  private

  def load_vars
    case params[:object_type]
    when 'Repository'
      @model = Repository.viewable_by_user(current_user).find_by(id: params[:object_id])
    when 'StorageLocation'
      @model = StorageLocation.viewable_by_user(current_user).find_by(id: params[:object_id])
    end

    render_404 unless @model
  end

  def create_params
    params.permit(:team_id, :object_type, :object_id, :target_team_id, :permission_level)
  end

  def destroy_params
    params.permit(:team_id, :id)
  end

  def update_params
    params.permit(permission_changes: {}, share_team_ids: [], write_permissions: [])
  end

  def check_sharing_permissions
    object_name = @model.is_a?(RepositoryBase) ? 'repository' : @model.model_name.param_key
    render_403 unless public_send("can_share_#{object_name}?", @model)
    render_403 if !@model.shareable_write? && update_params[:write_permissions].present?
  end

  def share_all_params
    {
      shared_with_all: params[:select_all_teams].present?,
      shared_permissions_level: params[:select_all_write_permission].present? ? 'shared_write' : 'shared_read'
    }
  end

  def setup_team_share_activity(team_shared_object, new_record)
    type =
      case @model
      when Repository
        if team_shared_object.destroyed?
          :unshare_inventory
        elsif new_record
          :share_inventory
        else
          :update_share_inventory
        end
      when StorageLocation
        if team_shared_object.destroyed?
          "#{'container_' if @model.container?}storage_location_unshared"
        elsif new_record
          "#{'container_' if @model.container?}storage_location_shared"
        else
          "#{'container_' if @model.container?}storage_location_sharing_updated"
        end
      end

    @activities_to_log << {
      type: type,
      message_items: {
        @model.model_name.param_key.to_sym => team_shared_object.shared_object.id,
        team: team_shared_object.team.id,
        permission_level: Extends::SHARED_INVENTORIES_PL_MAPPINGS[team_shared_object.permission_level.to_sym]
      }
    }
  end

  def setup_repository_global_share_activity
    message_items = {
      repository: @model.id,
      team: @model.team.id,
      permission_level: Extends::SHARED_INVENTORIES_PL_MAPPINGS[@model.permission_level.to_sym]
    }

    activity_params =
      if @model.saved_changes['permission_level'][0] == 'not_shared'
        { type: :share_inventory_with_all, message_items: message_items }
      elsif @model.saved_changes['permission_level'][1] == 'not_shared'
        { type: :unshare_inventory_with_all, message_items: message_items }
      else
        { type: :update_share_with_all_permission_level, message_items: message_items }
      end

    @activities_to_log << activity_params
  end

  def log_activities
    @activities_to_log.each do |activity_params|
      Activities::CreateActivityService
        .call(activity_type: activity_params[:type],
              owner: current_user,
              team: @model.team,
              subject: @model,
              message_items: {
                user: current_user.id
              }.merge(activity_params[:message_items]))
    end
  end
end
