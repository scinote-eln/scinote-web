class RepositoriesController < ApplicationController
  before_action :load_vars
  before_action :check_view_all_permissions, only: :index
  before_action :check_edit_and_destroy_permissions, only:
    %(destroy destroy_modal rename_modal update)
  before_action :check_create_permissions, only:
    %(create_new_modal create)

  def index
    render('repositories/index')
  end

  def create_new_modal
    @new_repository = Repository.new
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'create_new_repository_modal.html.erb'
          )
        }
      end
    end
  end

  def create
    @repository = Repository.new(
      team: @team,
      created_by: current_user
    )
    @repository.assign_attributes(repository_params)

    respond_to do |format|
      format.json do
        if @repository.save
          flash[:success] = t('repositories.index.modal_create.success_flash',
                              name: @repository.name)
          render json: { url: team_repositories_path(repository: @repository) },
            status: :ok
        else
          render json: @repository.errors,
            status: :unprocessable_entity
        end
      end
    end
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
    @repository = Repository.find(params[:id])
    flash[:success] = t('repositories.index.delete_flash',
                        name: @repository.name)
    @repository.destroy
    redirect_to team_repositories_path
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
    @repository = Repository.find(params[:id])
    old_name = @repository.name
    @repository.update_attributes(repository_params)

    respond_to do |format|
      format.json do
        if @repository.save
          flash[:success] = t('repositories.index.rename_flash',
                              old_name: old_name, new_name: @repository.name)
          render json: {
            url: team_repositories_path(repository: @repository)
          }, status: :ok
        else
          render json: @repository.errors, status: :unprocessable_entity
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

  def check_create_permissions
    render_403 unless can_create_new_repository(@team)
  end

  def check_edit_and_destroy_permissions
    render_403 unless can_edit_and_destroy_repository(@repository)
  end

  def repository_params
    params.require(:repository).permit(:name)
  end
end
