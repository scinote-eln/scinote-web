# frozen_string_literal: true

class TeamSharedObjectsController < ApplicationController
  before_action :load_vars
  before_action :check_sharing_permissions

  def update
    ActiveRecord::Base.transaction do
      # Global share
      if params[:select_all_teams]
        @model.update!(permission_level: params[:select_all_write_permission] ? :shared_write : :shared_read)
        @model.team_shared_objects.each(&:destroy!)
        next
      end

      # Share to specific teams
      params[:team_share_params].each do |t|
        @model.update!(permission_level: :not_shared) if @model.globally_shareable?
        @model.team_shared_objects.find_or_initialize_by(team_id: t['id']).update!(
          permission_level: t['private_shared_with_write'] ? :shared_write : :shared_read
        )
      end

      # Unshare
      @model.team_shared_objects.where.not(
        team_id: params[:team_share_params].filter { |t| t['private_shared_with'] }.pluck('id')
      ).each(&:destroy!)
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
    render_403 unless public_send("can_share_#{@model.model_name.param_key}?", @model)
    render_403 if !@model.shareable_write? && update_params[:write_permissions].present?
  end

  def share_all_params
    {
      shared_with_all: params[:select_all_teams].present?,
      shared_permissions_level: params[:select_all_write_permission].present? ? 'shared_write' : 'shared_read'
    }
  end

  def log_activity(type_of, team_shared_object)
    # log activity logic
  end
end
