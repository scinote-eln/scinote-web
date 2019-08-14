# frozen_string_literal: true

class TeamRepositoriesController < ApplicationController
  before_action :load_vars
  before_action :check_sharing_permissions, only: %i(create destroy)

  # POST :team_id/repositories/:repository_id/team_repositories
  def create
    team_repository = TeamRepository.new(repository: @repository,
                                         team_id: create_params[:target_team_id],
                                         permission_level: create_params[:permission_level])

    if team_repository.save
      log_activity(:share_inventory, team_repository)

      render json: { team_repository: team_repository }, status: :ok
    else
      render json: { team_repository: { message: 'not saved!', errors: team_repository.errors } },
             status: :unprocessable_entity
    end
  end

  # DELETE :team_id/repositories/:repository_id/team_repositories/:id
  def destroy
    team_repository = @repository.team_repositories.find_by_id(destory_params[:id])

    if team_repository
      log_activity(:unshare_inventory, team_repository)
      team_repository.destroy
      render json: {}, status: :no_content
    else
      render json: { message: 'Can\'t find sharing relation for destroy' }, status: :unprocessable_entity
    end
  end

  # POST :team_id/repositories/:repository_id/multiple_update
  def multiple_update
    service_call = Repositories::MultipleShareUpdateService.call(repository_id: @repository.id,
                                                                 user_id: current_user.id,
                                                                 team_id: current_team.id,
                                                                 team_ids_for_share: teams_to_share,
                                                                 team_ids_for_unshare: teams_to_unshare,
                                                                 team_ids_for_update: teams_to_update,
                                                                 **share_all_params)
    if service_call.succeed?
      render json: { warnings: service_call.warnings.join(', ') }, status: :ok
    else
      render json: { errors: service_call.errors.map { |_, v| v }.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def load_vars
    @repository = Repository.find_by_id(params[:repository_id])

    render_404 unless @repository
  end

  def create_params
    params.permit(:team_id, :repository_id, :target_team_id, :permission_level)
  end

  def destory_params
    params.permit(:team_id, :id)
  end

  def multiple_update_params
    params.permit(:permission_changes, share_team_ids: [], write_permissions: [])
  end

  def check_sharing_permissions
    render_403 unless can_manage_repository?(@repository)
  end

  def teams_to_share
    existing_shares = @repository.teams_shared_with.pluck(:id)
    teams_to_share = multiple_update_params[:share_team_ids]&.map(&:to_i).to_a - existing_shares
    wp = multiple_update_params[:write_permissions]&.map(&:to_i)

    teams_to_share.map { |e| { id: e, permission_level: wp&.include?(e) ? 'write' : 'read' } }
  end

  def teams_to_unshare
    existing_shares = @repository.teams_shared_with.pluck(:id)
    existing_shares - multiple_update_params[:share_team_ids]&.map(&:to_i).to_a
  end

  def teams_to_update
    teams_to_update = JSON.parse(multiple_update_params[:permission_changes]).keys.map(&:to_i).to_a &
                      multiple_update_params[:share_team_ids]&.map(&:to_i).to_a
    wp = multiple_update_params[:write_permissions]&.map(&:to_i)

    teams_to_update.map { |e| { id: e, permission_level: wp&.include?(e) ? 'write' : 'read' } }
  end

  def share_all_params
    {
      shared_with_all: params[:select_all_teams].present?,
      shared_permissions_level: params[:select_all_write_permission].present? ? 'write' : 'read'
    }
  end

  def log_activity(type_of, team_repository)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: team_repository.repository,
            team: current_team,
            message_items: { repository: team_repository.repository.id,
                             team: team_repository.team.id,
                             permission_level:
                               Extends::SHARED_INVENTORIES_PL_MAPPINGS[team_repository.permission_level.to_sym] })
  end
end
