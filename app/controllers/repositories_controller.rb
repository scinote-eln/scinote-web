class RepositoriesController < ApplicationController
  before_action :load_vars
  before_action :check_view_all_permissions, only: :index

  def index
    render('repositories/index')
  end

  def destroy_modal
    @repository = Repository.find(params[:repository_id])
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'delete_repository_modal.html.erb'
          )
        }
      end
    end
  end

  def destroy
    @repo = Repository.find(params[:id])
    @repo.destroy if @repo

    respond_to do |format|
      format.js { render inline: 'location.reload();' }
    end
  end

  private

  def load_vars
    @team = Team.find_by_id(params[:team_id])
    render_404 unless @team
    @repositories = @team.repositories.order(created_at: :asc)
  end

  def check_view_all_permissions
    render_403 unless can_view_team_repositories(@team)
  end
end
