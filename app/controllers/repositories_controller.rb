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
    flash[:success] = t('repositories.index.delete_flash', name: @repo.name)
    @repo.destroy
    redirect_to :back
  end

  def rename_modal
    @repository = Repository.find(params[:repository_id])
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'rename_repository_modal.html.erb'
          )
        }
      end
    end
  end

  def update
    @repo = Repository.find(params[:id])
    old_name = @repo.name
    @repo.update_attributes(repository_params)

    respond_to do |format|
      format.json do
        if @repo.save
          flash[:success] = t('repositories.index.rename_flash',
                              old_name: old_name, new_name: @repo.name)
          render json: {}, status: :ok
        else
          render json: @repo.errors, status: :unprocessable_entity
        end
      end
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

  def repository_params
    params.require(:repository).permit(:name)
  end
end
