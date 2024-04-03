# frozen_string_literal: true

class TeamRepositoriesController < ApplicationController
  before_action :load_vars
  before_action :check_sharing_permissions

  # DELETE :team_id/repositories/:repository_id/team_repositories/:id
  def destroy
    team_shared_object = @repository.team_shared_objects.find(destroy_params[:id])
    ActiveRecord::Base.transaction do
      log_activity(:unshare_inventory, team_shared_object)
      team_shared_object.destroy!
    end
    render json: {}, status: :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { message: I18n.t('repositories.multiple_share_service.nothing_to_delete') },
           status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { message: I18n.t('general.error') }, status: :unprocessable_entity
  end

  # POST :team_id/repositories/:repository_id/update
  def update
    service_call = Repositories::MultipleShareUpdateService.call(repository: @repository,
                                                                 user: current_user,
                                                                 team: current_team,
                                                                 team_ids_for_share: teams_to_share,
                                                                 team_ids_for_unshare: teams_to_unshare,
                                                                 team_ids_for_update: teams_to_update,
                                                                 **share_all_params)
    if service_call.succeed?
      render json: { warnings: service_call.warnings.join(', '), status: @repository.i_shared?(current_team) },
             status: :ok
    else
      render json: { errors: service_call.errors.map { |_, v| v }.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def load_vars
    @repository = current_team.repositories.find_by(id: params[:repository_id])

    render_404 unless @repository
  end

  def create_params
    params.permit(:team_id, :repository_id, :target_team_id, :permission_level)
  end

  def destroy_params
    params.permit(:team_id, :id)
  end

  def update_params
    params.permit(permission_changes: {}, share_team_ids: [], write_permissions: [])
  end

  def check_sharing_permissions
    render_403 unless can_share_repository?(@repository)
    render_403 if !@repository.shareable_write? && update_params[:write_permissions].present?
  end

  def teams_to_share
    existing_shares = @repository.teams_shared_with.pluck(:id)
    teams_to_share = update_params[:share_team_ids]&.map(&:to_i).to_a - existing_shares
    wp = update_params[:write_permissions]&.map(&:to_i)

    teams_to_share.map { |e| { id: e, permission_level: wp&.include?(e) ? 'shared_write' : 'shared_read' } }
  end

  def teams_to_unshare
    existing_shares = @repository.teams_shared_with.pluck(:id)
    existing_shares - update_params[:share_team_ids]&.map(&:to_i).to_a
  end

  def teams_to_update
    return [] if update_params[:permission_changes].blank?

    teams_to_update = update_params[:permission_changes].keys.map(&:to_i).to_a &
                      update_params[:share_team_ids]&.map(&:to_i).to_a
    wp = update_params[:write_permissions]&.map(&:to_i)

    teams_to_update.map { |e| { id: e, permission_level: wp&.include?(e) ? 'shared_write' : 'shared_read' } }
  end

  def share_all_params
    {
      shared_with_all: params[:select_all_teams].present?,
      shared_permissions_level: params[:select_all_write_permission].present? ? 'shared_write' : 'shared_read'
    }
  end

  def log_activity(type_of, team_shared_object)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: team_shared_object.shared_repository,
            team: @repository.team,
            message_items: { repository: team_shared_object.shared_repository.id,
                             team: team_shared_object.team.id,
                             permission_level:
                               Extends::SHARED_INVENTORIES_PL_MAPPINGS[team_shared_object.permission_level.to_sym] })
  end
end
