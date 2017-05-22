class RepositoriesController < ApplicationController
  before_action :load_vars
  before_action :check_view_all_permissions, only: :index

  def index
    render('repositories/index')
  end

  private

  def load_vars
    @team = Team.find_by_id(params[:team_id])
    @repositories = @team.repositories.order(created_at: :asc)

    render_404 unless @team
  end

  def check_view_all_permissions
    render_403 unless can_view_team_repositories(@team)
  end
end
