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
      render json: { team_repository: team_repository }, status: :ok
    else
      render json: { team_repository: { message: 'not saved!', errors: team_repository.errors } },
             status: :unprocessable_entity
    end
  end

  # DELETE :team_id/repositories/:repository_id/team_repositories/:id
  def destroy
    team_repository = @repository.team_repositories.find(destory_params[:id])
    team_repository.destroy
    render json: { message: 'destroyed!' }, status: :no_content
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

  def check_sharing_permissions
    render_403 unless can_manage_repository?(@repository)
  end
end
