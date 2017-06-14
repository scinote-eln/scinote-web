class RepositoriesController < ApplicationController
  before_action :load_vars, except: [:repository_table_index, :parse_sheet]
  before_action :check_view_all_permissions, only: :index
  before_action :check_edit_and_destroy_permissions, only:
    %(destroy destroy_modal rename_modal update)
  before_action :check_copy_permissions, only:
    %(copy_modal copy)
  before_action :check_create_permissions, only:
    %(create_new_modal create)

  def index
    render('repositories/index')
  end

  def show_tab
    @repository = Repository.find_by_id(params[:repository_id])
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'repositories/repository.html.erb',
            locals: { repository: @repository }
          )
        }
      end
    end
  end

  def create_modal
    @repository = Repository.new
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'create_repository_modal.html.erb'
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

  def copy_modal
    @repository = Repository.find(params[:repository_id])
    @tmp_repository = Repository.new(
      team: @team,
      created_by: current_user,
      name: @repository.name
    )
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'copy_repository_modal.html.erb'
          )
        }
      end
    end
  end

  def copy
    @repository = Repository.find(params[:repository_id])
    @tmp_repository = Repository.new(
      team: @team,
      created_by: current_user
    )
    @tmp_repository.assign_attributes(repository_params)

    respond_to do |format|
      format.json do
        if !@tmp_repository.valid?
          render json: @tmp_repository.errors, status: :unprocessable_entity
        else
          copied_repository =
            @repository.copy(current_user, @tmp_repository.name)

          if !copied_repository
            render json: { 'name': ['Server error'] },
            status: :unprocessable_entity
          else
            flash[:success] = t(
              'repositories.index.copy_flash',
              old: @repository.name,
              new: copied_repository.name
            )
            render json: {
              url: team_repositories_path(repository: copied_repository)
            }, status: :ok
          end
        end
      end
    end
  end

  # AJAX actions
  def repository_table_index
    @repository = Repository.find_by_id(params[:repository_id])
    if @repository.nil? || !can_view_repository(@repository)
      render_403
    else
      respond_to do |format|
        format.html
        format.json do
          render json: ::RepositoryDatatable.new(view_context,
                                                 @repository,
                                                 nil,
                                                 current_user)
        end
      end
    end
  end

  def parse_sheet
    render_404 unless params[:team_id].to_i == current_team.id
    repository = current_team.repositories.find_by_id(params[:id])
    imported_file = ::ImportRepository.new(file: params[:file],
                                               repository: repository,
                                               session: session)

    respond_to do |format|
      unless params[:file]
        repository_response(t("teams.parse_sheet.errors.no_file_selected"))
      end
      begin
        if imported_file.too_large?
          repository_response(t('general.file.size_exceeded',
                                file_size: Constants::FILE_MAX_SIZE_MB))
        else
          flash[:notice] = t('teams.parse_sheet.errors.empty_file')
          redirect_to back and return if imported_file.empty?
          @import_data = imported_file.data
          if imported_file.generated_temp_file?
            format.json do
              render json: {
                html: render_to_string(
                  partial: 'repositories/parse_records_modal.html.erb'
                )
              }
            end
          else
            repository_response(t('teams.parse_sheet.errors.temp_file_failure'))
          end
        end
      rescue ArgumentError, CSV::MalformedCSVError
        repository_response(t('teams.parse_sheet.errors.invalid_file',
                              encoding: ''.encoding))
      rescue TypeError
        repository_response(t('teams.parse_sheet.errors.invalid_extension'))
      end
    end
  end

  def import_repository
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
    render_403 unless can_create_repository(@team)
  end

  def check_edit_and_destroy_permissions
    render_403 unless can_edit_and_destroy_repository(@repository)
  end

  def check_copy_permissions
    render_403 unless can_copy_repository(@repository)
  end

  def repository_params
    params.require(:repository).permit(:name)
  end

  def repository_response(message)
    format.html do
      flash[:alert] = message
      redirect_to :back
    end
    format.json do
      render json: { message: message },
        status: :unprocessable_entity
    end
  end
end
